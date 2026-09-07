#!/usr/bin/env bash
#
# Generate circular-ready face thumbnails from the crop coordinates in
# entries.json.
#
# Each entry may carry a "crop" object:
#
#   "crop": { "x": 0.615, "y": 0.415, "r": 0.125 }
#
# x and y are the crop centre as a fraction of width and height. r is the
# half-side of the square crop as a fraction of the SHORTER edge, so the
# same number means the same physical framing whether the photo is
# portrait or landscape. Entries without a crop are skipped; the page
# falls back to a plain marker for those.
#
# Output: photos/thumbs/NNN.jpg (128px) and NNN@2x.jpg (256px), EXIF
# stripped. The page masks them into circles with CSS, so these stay
# square — no transparency needed, which keeps them as small JPEGs.
#
# Usage:
#   ./scripts/make-thumbs.sh              # all entries
#   ./scripts/make-thumbs.sh 007 013      # only these

set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v magick >/dev/null 2>&1; then
  cat >&2 <<EOF
error: ImageMagick (magick) not found.

Install with:
  brew install imagemagick              (macOS)
  sudo apt install imagemagick          (Debian/Ubuntu)
EOF
  exit 1
fi

SIZE=128
OUT=photos/thumbs
mkdir -p "$OUT"

# Emit "NNN x y r" per entry that has a crop, filtered by any args given.
coords=$(python3 - "$@" <<'PY'
import json, sys, re
want = set(sys.argv[1:])
for e in json.load(open('entries.json'))['entries']:
    c = e.get('crop')
    if not c:
        continue
    m = re.search(r'(\d{3})\.jpg$', e.get('photo') or '')
    if not m or (want and m.group(1) not in want):
        continue
    print(m.group(1), c['x'], c['y'], c['r'])
PY
)

if [ -z "$coords" ]; then
  echo "no entries with crop coordinates matched" >&2
  exit 1
fi

made=0
while read -r n x y r; do
  src="photos/$n.jpg"
  if [ ! -f "$src" ]; then
    echo "skip: $src (missing)" >&2
    continue
  fi

  W=$(magick identify -format '%w' "$src")
  H=$(magick identify -format '%h' "$src")

  # Square side from the shorter edge, then clamp the origin so the crop
  # never runs off the image when a bird sits near the frame edge.
  read -r side ox oy <<< "$(python3 -c "
import sys
W,H,x,y,r = int(sys.argv[1]),int(sys.argv[2]),float(sys.argv[3]),float(sys.argv[4]),float(sys.argv[5])
side = max(16, min(round(2*r*min(W,H)), W, H))
ox = min(max(round(x*W - side/2), 0), W - side)
oy = min(max(round(y*H - side/2), 0), H - side)
print(side, ox, oy)
" "$W" "$H" "$x" "$y" "$r")"

  magick "$src" -crop "${side}x${side}+${ox}+${oy}" +repage \
    -resize "$((SIZE*2))x$((SIZE*2))" -strip -quality 82 "$OUT/$n@2x.jpg"
  magick "$OUT/$n@2x.jpg" -resize "${SIZE}x${SIZE}" -strip -quality 82 "$OUT/$n.jpg"

  echo "thumb: $n  ${side}px @ +${ox}+${oy}"
  made=$((made + 1))
done <<< "$coords"

echo
echo "done. generated: $made  ->  $OUT/"
du -sh "$OUT"
