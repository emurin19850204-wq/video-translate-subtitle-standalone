---
name: video-translate-subtitle
description: Translate English speech in authorized video files into Japanese and burn readable subtitles into an MP4 using standard FFmpeg, Python, and a replaceable timestamped transcription adapter. Use for English-to-Japanese video subtitle production, SRT creation, visual black/white screen checks, title-card or scene-change reporting, and delivery of MP4 plus subtitle/report artifacts.
---

# Portable English video to Japanese-subtitled MP4

Use this skill to turn an authorized English-language video into a Japanese-subtitled MP4 without depending on a particular AI vendor, agent runtime, browser session, or proprietary CLI. Use POSIX shell, FFmpeg/ffprobe, Python 3, and any approved timestamped transcription adapter available in the host application.

> Do not bypass authentication, access controls, paywalls, download restrictions, or DRM. Use a local file or another authorized acquisition method.

## Workflow

1. Acquire or receive a local source MP4 through an authorized method.
2. Probe the source and analyze its visual structure before translating.
3. Transcribe the English speech with timestamps through a replaceable adapter.
4. Normalize the transcript to JSON segments with `start`, `end`, and `text`.
5. Translate the English text into concise, natural Japanese without changing meaning.
6. Convert translated JSON to SRT or prepare an existing SRT.
7. Validate the SRT.
8. Burn the SRT into an un-cropped MP4.
9. Verify output metadata and subtitle legibility.
10. Report black/white screens, title cards, alternate images, and scene changes with exact intervals.
11. Deliver the MP4, SRT, report, and preview image.

## Runtime requirements

Require `ffmpeg`, `ffprobe`, Python 3, and a UTF-8-capable shell. Resolve `Noto Sans CJK JP` with `fc-match` when available. Use Whisper, faster-whisper, whisper.cpp, an approved cloud speech-to-text API, or a user-provided transcript as the transcription adapter. Keep credentials in environment variables or an approved secret store. Never commit credentials to this repository.

## Source probing and visual analysis

Probe the source:

```bash
ffprobe -v error \
  -show_entries format=duration,size,bit_rate:stream=index,codec_name,codec_type,width,height,r_frame_rate \
  -of json source.mp4 > analysis/ffprobe.json
```

Run the bundled analyzer:

```bash
bash "$SKILL_DIR/scripts/analyze_video.sh" source.mp4 analysis
```

Review `analysis/contact_sheet_*s.jpg`, `black_intervals.txt`, `white_intervals.txt`, `scene_timestamps.txt`, and `ffprobe.json`. Create additional timestamped intro/end frame sheets when a boundary needs visual confirmation. Distinguish a black logo/title background from a full black transition, and distinguish normal camera changes from a separate image or scene. Preserve all original content in the final video and report it instead of removing it.

## Transcript adapter contract

Normalize the output from any speech-to-text provider to this JSON shape:

```json
[
  {"start": 0.0, "end": 2.4, "text": "Welcome to the course."},
  {"start": 2.6, "end": 5.1, "text": "Today we will review the next steps."}
]
```

`start` and `end` are seconds or SubRip timestamps. `text` is the spoken English. An object containing a `segments` array is also accepted. If timestamps are missing, estimate them conservatively from sentence boundaries and state that the timings are estimated in the report.

## Translation rules

Translate meaning rather than word order. Keep proper names, branded course names, exercise names, movement-standard terminology, numbers, units, and safety instructions consistent. Do not add explanations or coaching advice that was not spoken. Prefer one or two short Japanese lines per cue. Split overlong cues only at natural clause boundaries and never create overlapping cues.

## Create and validate SRT

After translating the JSON `text` fields into Japanese, convert the segments:

```bash
python3 "$SKILL_DIR/scripts/transcript_to_srt.py" \
  translated_segments.json japanese.srt
```

Validate before encoding:

```bash
python3 "$SKILL_DIR/scripts/validate_srt.py" japanese.srt
```

Fix all errors. Review warnings about long captions or very short cues. Save UTF-8 SRT with a trailing newline.

## Burn subtitles

Burn subtitles without cropping:

```bash
bash "$SKILL_DIR/scripts/burn_japanese_subtitles.sh" \
  source.mp4 japanese.srt output/日本語字幕付き.mp4
```

The encoder uses Noto Sans CJK JP when installed, white text with a black outline, centered bottom alignment, and a semi-transparent black lower background. It uses font size 24 with a 1080p-proportional box for 1080p and font size 20 with a 720p-proportional box for 720p. It encodes video with libx264, medium preset, CRF 18, faststart, and copies AAC audio when compatible; otherwise it encodes standard AAC.

## Verify output

Probe the output and compare duration, resolution, and audio with the source:

```bash
ffprobe -v error \
  -show_entries format=duration,size:stream=index,codec_name,codec_type,width,height,r_frame_rate \
  -of json output/日本語字幕付き.mp4
```

Generate representative frames from early, middle, and late subtitle cues. Confirm that Japanese characters render correctly, the background covers the lower subtitle area, text is not clipped, and essential visual content remains visible. If the output is silent, truncated, cropped, or malformed, fix it before delivery.

## Delivery report

Use [references/report-template.md](references/report-template.md). Include the source title, completed MP4 path, resolution, duration, codecs, subtitle font, encoding settings, subtitle coverage, estimated-timing notes, and exact intervals for black screens, white screens, title cards, alternate images, and alternate scenes. State explicitly when no white screen or unrelated scene was found. Deliver the MP4 first, then the SRT, report, and preview image.

## Non-video pages

If the source page contains only text, slides, or an interactive lesson and no video/audio resource, do not fabricate an MP4. Report that the content is not a translatable video and offer a text translation instead. If multiple videos exist, process each separately and identify outputs by title or filename.

## AI application integration

For Claude Code, install the skill under `.claude/skills/video-translate-subtitle/` and use `/video-translate-subtitle`. For Codex, install it under `.agents/skills/video-translate-subtitle/` and use `$video-translate-subtitle`. Other Agent Skills-compatible applications can load this same `SKILL.md`; applications without skill support can call the bundled scripts directly. See [references/portable-installation.md](references/portable-installation.md).
