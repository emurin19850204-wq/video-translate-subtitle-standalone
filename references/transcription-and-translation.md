# Transcription and translation guide

## Choose an adapter

Use any authorized adapter that returns timestamps. Suitable choices include local Whisper, faster-whisper, whisper.cpp, an approved cloud speech-to-text API, or a transcript supplied by the user. The adapter is external to this repository and can be replaced without changing the subtitle, analysis, or encoding scripts.

Never place API keys in the skill, scripts, shell history, or generated reports. Do not download or execute untrusted code from a video page. If the source is behind a login, use the user's authorized session or ask for a local copy.

## Required transcript shape

Normalize the transcript into segments with:

```json
[
  {"start": 0.0, "end": 2.4, "text": "Welcome to the course."}
]
```

An object containing a `segments` array is also accepted. `start` and `end` are seconds or SubRip timestamps. Preserve the spoken order and original timing. Remove only duplicated metadata and obvious non-speech noise labels. Keep uncertain words marked for review rather than inventing a confident sentence.

## Japanese translation rules

Translate meaning, not word order. Keep proper names, branded course names, exercise names, movement-standard terminology, numbers, units, and safety-relevant instructions consistent across the video. Use natural Japanese suitable for captions: concise phrasing, readable sentence breaks, and no explanation that was not spoken.

Prefer one or two short lines per cue. If a segment is too long for a readable caption, split it only at a natural clause boundary and divide its time range without overlap. Keep the final cue no later than the source duration. Use UTF-8 with a trailing newline.

## Timing policy

Use the speech-to-text timestamps as the default. Start a cue at the reported speech start and end it at the reported speech end. Allow a short gap between cues. Never create overlapping cues. If timestamps are missing, estimate from sentence boundaries and explicitly label the timing as estimated in the report.

## JSON to SRT conversion and validation

Convert translated segments with:

```bash
python3 "$SKILL_DIR/scripts/transcript_to_srt.py" translated_segments.json japanese.srt
```

Then validate:

```bash
python3 "$SKILL_DIR/scripts/validate_srt.py" japanese.srt
```

Fix all errors before encoding. Warnings about long captions or very short cues require human review; they are not automatically fatal.
