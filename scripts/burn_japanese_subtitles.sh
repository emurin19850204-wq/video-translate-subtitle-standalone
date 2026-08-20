#!/usr/bin/env bash
# Burn Japanese subtitles into an MP4 without cropping or changing the frame.
# Usage: burn_japanese_subtitles.sh SOURCE.mp4 SUBTITLES.srt OUTPUT.mp4
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 SOURCE.mp4 SUBTITLES.srt OUTPUT.mp4" >&2
  exit 2
fi

INPUT=$1
SRT=$2
OUTPUT=$3

for path in "$INPUT" "$SRT"; do
  [[ -f "$path" ]] || { echo "error: file not found: $path" >&2; exit 2; }
done
for command in ffmpeg ffprobe fc-match; do
  command -v "$command" >/dev/null || { echo "error: required command not found: $command" >&2; exit 2; }
done

WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT")
HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT")
[[ "$WIDTH" =~ ^[0-9]+$ && "$HEIGHT" =~ ^[0-9]+$ ]] || { echo "error: could not read video dimensions" >&2; exit 1; }

# Use the established 1080p/720p style and scale the lower background for
# other resolutions. Keep text readable without altering the original frame.
if (( HEIGHT >= 900 )); then
  FONT_SIZE=24
  BOX_HEIGHT=$(( HEIGHT * 180 / 1080 ))
  MARGIN_V=$(( HEIGHT * 38 / 1080 ))
elif (( HEIGHT >= 600 )); then
  FONT_SIZE=20
  BOX_HEIGHT=$(( HEIGHT * 120 / 720 ))
  MARGIN_V=$(( HEIGHT * 26 / 720 ))
else
  FONT_SIZE=$(( HEIGHT * 20 / 720 ))
  (( FONT_SIZE < 14 )) && FONT_SIZE=14
  BOX_HEIGHT=$(( HEIGHT / 6 ))
  MARGIN_V=$(( HEIGHT / 24 ))
fi
BOX_Y=$(( HEIGHT - BOX_HEIGHT ))

# Prefer the requested CJK font, while recording the actual resolved family.
FONT_NAME=$(fc-match -f '%{family}' 'Noto Sans CJK JP' | head -n 1)
if [[ -z "$FONT_NAME" ]]; then
  FONT_NAME=$(fc-match -f '%{family}' sans | head -n 1)
fi
mkdir -p "$(dirname "$OUTPUT")"
printf 'source=%s\nresolution=%sx%s\nfont=%s\nfont_size=%s\nbox_y=%s\nbox_height=%s\nmargin_v=%s\n' \
  "$INPUT" "$WIDTH" "$HEIGHT" "$FONT_NAME" "$FONT_SIZE" "$BOX_Y" "$BOX_HEIGHT" "$MARGIN_V" \
  > "${OUTPUT%.*}.burn_settings.txt"

# Escape the path separator recognized by the subtitles filter. The preferred
# invocation is intentionally direct so it works in POSIX shells and Codex.
SRT_FILTER_PATH=${SRT//:/\\:}
FORCE_STYLE="FontName=${FONT_NAME},FontSize=${FONT_SIZE},PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=2,Shadow=0,Alignment=2,MarginV=${MARGIN_V}"
FILTER="drawbox=x=0:y=${BOX_Y}:w=${WIDTH}:h=${BOX_HEIGHT}:color=black@0.65:t=fill,subtitles=${SRT_FILTER_PATH}:force_style='${FORCE_STYLE}'"

# Copy AAC when the container permits it. If the source audio is incompatible,
# retry with a standard AAC encode rather than failing after video processing.
if ffmpeg -y -hide_banner -loglevel error -i "$INPUT" \
    -map 0:v:0 -map 0:a? -vf "$FILTER" \
    -c:v libx264 -preset medium -crf 18 -c:a copy -movflags +faststart "$OUTPUT"; then
  exit 0
fi

ffmpeg -y -hide_banner -loglevel error -i "$INPUT" \
  -map 0:v:0 -map 0:a? -vf "$FILTER" \
  -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 192k -movflags +faststart "$OUTPUT"
