#!/usr/bin/env bash
#
# Strip GPS metadata from photos before publishing.
#
# Keeps technical EXIF (camera model, lens, exposure) intentionally as
# part of the field-log aesthetic. Removes GPS coordinates because
# location lives in entries.json where we control precision.
#
# Usage:
#   ./scripts/strip-exif.sh photos/*.jpg
#   ./scripts/strip-exif.sh path/to/single.jpg

set -euo pipefail

if [ $# -eq 0 ]; then
  cat >&2 <<EOF
usage: $0 <photo.jpg> [photo2.jpg ...]

Strips GPS-related EXIF tags (GPSLatitude, GPSLongitude, GPSAltitude,
GPSTimeStamp, etc.) from each photo in place. Other EXIF is preserved.
EOF
  exit 1
fi

if ! command -v exiftool >/dev/null 2>&1; then
  cat >&2 <<EOF
error: exiftool not found.

Install with:
  brew install exiftool                 (macOS)
  sudo apt install libimage-exiftool-perl  (Debian/Ubuntu)
  sudo dnf install perl-Image-ExifTool  (Fedora)
EOF
  exit 1
fi

stripped=0
skipped=0

for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "skip: $f (not a file)" >&2
    skipped=$((skipped + 1))
    continue
  fi
  exiftool -q -gps:all= -overwrite_original "$f" > /dev/null
  echo "stripped GPS: $f"
  stripped=$((stripped + 1))
done

echo
echo "done. stripped: $stripped, skipped: $skipped"
