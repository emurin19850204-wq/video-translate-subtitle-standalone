#!/usr/bin/env bash
# Analyze a source video for metadata, black/white frames, scene changes, and
# a timestamped contact sheet.
# Usage: analyze_video.sh SOURCE.mp4 [OUTPUT_DIR]
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 SOURCE.mp4 [OUTPUT_DIR]" >&2
  exit 2
fi

INPUT=$1
OUT_DIR=${2:-"${INPUT%.*}_analysis"}
INTERVAL=${CONTACT_INTERVAL:-5}
COLS=${CONTACT_COLS:-5}
THUMB_WIDTH=${CONTACT_THUMB_WIDTH:-320}

if [[ ! -f "$INPUT" ]]; then
  echo "error: source not found: $INPUT" >&2
  exit 2
fi
for command in ffprobe ffmpeg awk grep sed; do
  command -v "$command" >/dev/null || { echo "error: required command not found: $command" >&2; exit 2; }
done
mkdir -p "$OUT_DIR"

ffprobe -v error \
  -show_entries format=duration,size,bit_rate:stream=index,codec_name,codec_type,width,height,r_frame_rate \
  -of json "$INPUT" > "$OUT_DIR/ffprobe.json"

duration=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$INPUT")
if [[ -z "$duration" ]]; then
  echo "error: could not read video duration" >&2
  exit 1
fi
sample_count=$(awk -v d="$duration" -v i="$INTERVAL" 'BEGIN { print int((d+i-0.000001)/i) }')
rows=$(( (sample_count + COLS - 1) / COLS ))

# Content analysis logs. A short threshold avoids reporting ordinary dark edges
# as a black screen, while keeping short transition fades visible.
ffmpeg -hide_banner -i "$INPUT" \
  -vf "blackdetect=d=0.05:pix_th=0.10" -an -f null - \
  2> "$OUT_DIR/blackdetect.log" || true
ffmpeg -hide_banner -i "$INPUT" \
  -vf "whitedetect=d=0.05:pix_th=0.98" -an -f null - \
  2> "$OUT_DIR/whitedetect.log" || true
ffmpeg -hide_banner -i "$INPUT" \
  -vf "select='gt(scene,0.40)',showinfo" -an -f null - \
  2> "$OUT_DIR/scene_candidates.log" || true

grep -E 'black_start|black_end|black_duration' "$OUT_DIR/blackdetect.log" \
  > "$OUT_DIR/black_intervals.txt" || true
grep -E 'white_start|white_end|white_duration' "$OUT_DIR/whitedetect.log" \
  > "$OUT_DIR/white_intervals.txt" || true
grep -E 'showinfo.*pts_time' "$OUT_DIR/scene_candidates.log" \
  > "$OUT_DIR/scene_timestamps.txt" || true

# A single overview sheet is useful for human review of title cards and
# alternate scenes. The timestamps are implicit in the fixed sampling interval;
# create edge sheets separately when exact visual boundaries matter.
ffmpeg -y -hide_banner -loglevel error -i "$INPUT" \
  -vf "fps=1/${INTERVAL},scale=${THUMB_WIDTH}:-1,tile=${COLS}x${rows}:padding=4:margin=4" \
  -frames:v 1 "$OUT_DIR/contact_sheet_${INTERVAL}s.jpg"

cat <<EOF
Analysis complete.
Source: $INPUT
Output: $OUT_DIR
Duration: $duration seconds
Contact interval: $INTERVAL seconds
Files: ffprobe.json, blackdetect.log, white[detect].log, scene_candidates.log,
       black_intervals.txt, white_intervals.txt, scene_timestamps.txt,
       contact_sheet_${INTERVAL}s.jpg
EOF
