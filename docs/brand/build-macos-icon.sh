#!/usr/bin/env bash
# Rebuild the stable macOS Dock/Finder icon from the user-supplied SVG.
# Requires macOS (sips and iconutil); no external image dependencies.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source_svg="$root/docs/brand/sources/star-app-icon-original.svg"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Render the vector paths at full 1024px resolution, not a scaled-up 250px bitmap.
python3 - "$source_svg" "$work/star-app-icon-1024.svg" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text(encoding="utf-8")
old = 'width="250" height="250"'
assert source.startswith("<svg " + old), "Original SVG viewBox/dimensions have changed"
Path(sys.argv[2]).write_text(source.replace(old, 'width="1024" height="1024"', 1))
PY

sips -s format png "$work/star-app-icon-1024.svg" --out "$work/master.png" >/dev/null
test "$(sips -g pixelWidth "$work/master.png" | tail -1 | awk '{print $2}')" = "1024"
iconset="$work/Star.iconset"
mkdir "$iconset"
for entry in \
  "16 icon_16x16.png" \
  "32 icon_16x16@2x.png" \
  "32 icon_32x32.png" \
  "64 icon_32x32@2x.png" \
  "128 icon_128x128.png" \
  "256 icon_128x128@2x.png" \
  "256 icon_256x256.png" \
  "512 icon_256x256@2x.png" \
  "512 icon_512x512.png" \
  "1024 icon_512x512@2x.png"; do
    read -r pixels name <<< "$entry"
    sips -z "$pixels" "$pixels" "$work/master.png" --out "$iconset/$name" >/dev/null
done

iconutil -c icns "$iconset" -o "$work/AppIcon.icns"
test "$(dd if="$work/AppIcon.icns" bs=1 count=4 2>/dev/null)" = "icns"

for component in "Star web" "Star Server"; do
  target="$root/$component/star_desktop/build_resources/icons-stable"
  install -m 644 "$work/AppIcon.icns" "$target/_compiled/AppIcon.icns"
  install -m 644 "$work/master.png" "$target/icon.png"
  for size in 16 24 32 48 64 128 256 512 1024; do
    sips -z "$size" "$size" "$work/master.png" --out "$target/${size}x${size}.png" >/dev/null
  done
  printf 'Updated %s macOS stable icon assets\n' "$component"
done

shasum -a 256 "$root/Star web/star_desktop/build_resources/icons-stable/_compiled/AppIcon.icns"
