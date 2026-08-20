#!/usr/bin/env python3
"""Validate a UTF-8 SubRip subtitle file.

Usage:
    python validate_srt.py subtitles.srt

The script checks numbering, timestamp syntax/order, overlaps, empty text,
UTF-8 decoding, and basic timestamp bounds. It exits non-zero on errors.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

TIMESTAMP_RE = re.compile(
    r"^(?P<h1>\d{2,}):(?P<m1>\d{2}):(?P<s1>\d{2}),(?P<ms1>\d{3})"
    r"\s+-->\s+"
    r"(?P<h2>\d{2,}):(?P<m2>\d{2}):(?P<s2>\d{2}),(?P<ms2>\d{3})$"
)


@dataclass
class Cue:
    number: int
    start: int
    end: int
    text: str
    line: int


def parse_timestamp(value: str) -> int:
    match = TIMESTAMP_RE.match(value)
    if not match:
        raise ValueError(f"invalid timestamp line: {value!r}")

    def ms(prefix: str) -> int:
        return (
            int(match[f"h{prefix}"]) * 3_600_000
            + int(match[f"m{prefix}"]) * 60_000
            + int(match[f"s{prefix}"]) * 1_000
            + int(match[f"ms{prefix}"])
        )

    return ms("1"), ms("2")


def read_blocks(path: Path) -> list[tuple[int, list[str]]]:
    raw = path.read_text(encoding="utf-8-sig")
    blocks: list[tuple[int, list[str]]] = []
    line_no = 1
    for block in re.split(r"\n\s*\n", raw.replace("\r\n", "\n").replace("\r", "\n")):
        lines = block.split("\n")
        while lines and not lines[0].strip():
            lines.pop(0)
            line_no += 1
        while lines and not lines[-1].strip():
            lines.pop()
        if lines:
            blocks.append((line_no, lines))
        line_no += len(lines) + 1
    return blocks


def validate(path: Path) -> tuple[list[str], list[str], list[Cue]]:
    errors: list[str] = []
    warnings: list[str] = []
    cues: list[Cue] = []
    try:
        blocks = read_blocks(path)
    except UnicodeDecodeError as exc:
        return [f"file is not valid UTF-8: {exc}"], [], []

    expected = 1
    for block_line, lines in blocks:
        if len(lines) < 3:
            errors.append(f"line {block_line}: cue must contain number, timing, and text")
            continue
        try:
            number = int(lines[0].strip())
        except ValueError:
            errors.append(f"line {block_line}: invalid cue number {lines[0]!r}")
            continue
        if number != expected:
            errors.append(f"line {block_line}: expected cue {expected}, found {number}")
        expected = number + 1
        try:
            start, end = parse_timestamp(lines[1].strip())
        except ValueError as exc:
            errors.append(f"line {block_line}: {exc}")
            continue
        text = "\n".join(lines[2:]).strip()
        if not text:
            errors.append(f"line {block_line}: empty subtitle text")
        if end <= start:
            errors.append(f"line {block_line}: end must be after start")
        if end - start < 250:
            warnings.append(f"line {block_line}: very short cue ({end - start} ms)")
        if len(text.replace("\n", " ")) > 90:
            warnings.append(f"line {block_line}: long subtitle ({len(text)} characters)")
        cues.append(Cue(number, start, end, text, block_line))

    for previous, current in zip(cues, cues[1:]):
        if current.start < previous.end:
            errors.append(
                f"line {current.line}: cue {current.number} overlaps cue {previous.number}"
            )
        if current.start < previous.start:
            errors.append(
                f"line {current.line}: cue {current.number} starts before the previous cue"
            )
    return errors, warnings, cues


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_srt.py subtitles.srt", file=sys.stderr)
        return 2
    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"error: file not found: {path}", file=sys.stderr)
        return 2
    errors, warnings, cues = validate(path)
    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}")
    if errors:
        print(f"INVALID: {path} ({len(errors)} error(s), {len(warnings)} warning(s))")
        return 1
    print(f"VALID: {path} ({len(cues)} cue(s), {len(warnings)} warning(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
