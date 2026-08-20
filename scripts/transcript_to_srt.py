#!/usr/bin/env python3
"""Convert timestamped JSON transcript segments to UTF-8 SRT.

Accepted input shapes:
- A JSON array of {start, end, text} objects.
- An object containing a `segments` array with the same objects.

`start` and `end` are seconds or SubRip timestamps. This script does not
translate text; supply already translated Japanese text when creating the SRT.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

SRT_TIME = re.compile(r"^(\d+):(\d{2}):(\d{2})[,.](\d{3})$")


def to_milliseconds(value: Any, label: str) -> int:
    if isinstance(value, bool):
        raise ValueError(f"{label} must be seconds or a timestamp, not boolean")
    if isinstance(value, (int, float)):
        milliseconds = round(float(value) * 1000)
    elif isinstance(value, str):
        raw = value.strip()
        match = SRT_TIME.match(raw)
        if match:
            hours, minutes, seconds, millis = map(int, match.groups())
            milliseconds = ((hours * 60 + minutes) * 60 + seconds) * 1000 + millis
        else:
            try:
                milliseconds = round(float(raw) * 1000)
            except ValueError as exc:
                raise ValueError(f"{label} is not a valid timestamp: {value!r}") from exc
    else:
        raise ValueError(f"{label} must be seconds or a timestamp")
    if milliseconds < 0:
        raise ValueError(f"{label} cannot be negative")
    return milliseconds


def format_timestamp(milliseconds: int) -> str:
    hours, remainder = divmod(milliseconds, 3_600_000)
    minutes, remainder = divmod(remainder, 60_000)
    seconds, millis = divmod(remainder, 1000)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d},{millis:03d}"


def load_segments(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8-sig") as handle:
        payload = json.load(handle)
    if isinstance(payload, dict):
        payload = payload.get("segments")
    if not isinstance(payload, list):
        raise ValueError("input must be a JSON array or an object with a segments array")
    return payload


def convert(segments: list[dict[str, Any]]) -> str:
    output: list[str] = []
    previous_end = -1
    cue_number = 1
    for index, segment in enumerate(segments, start=1):
        if not isinstance(segment, dict):
            raise ValueError(f"segment {index} must be an object")
        if not {"start", "end", "text"}.issubset(segment):
            raise ValueError(f"segment {index} must contain start, end, and text")
        start = to_milliseconds(segment["start"], f"segment {index} start")
        end = to_milliseconds(segment["end"], f"segment {index} end")
        text = str(segment["text"]).replace("\r\n", "\n").replace("\r", "\n").strip()
        if not text:
            raise ValueError(f"segment {index} has empty text")
        if end <= start:
            raise ValueError(f"segment {index} end must be after start")
        if start < previous_end:
            raise ValueError(f"segment {index} overlaps the previous segment")
        output.extend(
            [
                str(cue_number),
                f"{format_timestamp(start)} --> {format_timestamp(end)}",
                text,
                "",
            ]
        )
        previous_end = end
        cue_number += 1
    return "\n".join(output)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: transcript_to_srt.py transcript.json output.srt", file=sys.stderr)
        return 2
    source = Path(sys.argv[1])
    target = Path(sys.argv[2])
    if not source.is_file():
        print(f"error: input not found: {source}", file=sys.stderr)
        return 2
    try:
        srt = convert(load_segments(source))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(srt.rstrip() + "\n", encoding="utf-8")
    print(f"wrote {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
