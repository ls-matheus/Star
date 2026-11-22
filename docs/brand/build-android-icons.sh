#!/usr/bin/env bash
# Generate the Android Star launcher/splash icons from the user-provided vector.
# This is a macOS authoring script (requires sips), not an Android runtime step.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source_svg="$root/docs/brand/sources/star-app-icon-original.svg"
source_symbol="$root/docs/brand/sources/star-symbol-original.svg"
res="$root/Star mobile/android/app/src/main/res"
previews="$root/Star mobile/assets/images/app_icon_previews/android"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

python3 - "$source_svg" "$source_symbol" "$res" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET
source = ET.parse(sys.argv[1]).getroot()
symbol = ET.parse(sys.argv[2]).getroot()
res = Path(sys.argv[3])
android = "http://schemas.android.com/apk/res/android"
svg = "http://www.w3.org/2000/svg"
ET.register_namespace("android", android)
paths = [p.attrib["d"] for p in symbol.iter(f"{{{svg}}}path")]
original = [p.attrib["d"] for p in source.iter(f"{{{svg}}}path")]
assert len(paths) == len(original) == 2
# Both SVGs are original user artwork; source app icon is the authoritative
# 250x250 white star. The symbol artwork has different coordinates.
foreground = original
# Keep the white mark inside a comfortable 18% visual margin.

def vector(name, width, height, viewport, fill, source_paths, group=None):
    root = ET.Element("vector", {
        f"{{{android}}}width": f"{width}dp",
        f"{{{android}}}height": f"{height}dp",
        f"{{{android}}}viewportWidth": str(viewport),
        f"{{{android}}}viewportHeight": str(viewport),
    })
    holder = root
    if group is not None:
        holder = ET.SubElement(root,"group",{
            f"{{{android}}}translateX": "104" if group != "launcher" else "28",
            f"{{{android}}}translateY": "104" if group != "launcher" else "28",
            f"{{{android}}}scaleX": "0.28" if group != "launcher" else "0.78",
            f"{{{android}}}scaleY": "0.28" if group != "launcher" else "0.78",
        })
    for data in source_paths:
        ET.SubElement(holder,"path",{
            f"{{{android}}}fillColor": fill,
            f"{{{android}}}pathData": data,
        })
    path=res/"drawable"/f"{name}.xml"
    path.write_bytes(ET.tostring(root,encoding="utf-8",xml_declaration=True))
    print("Generated",path.name)

# On Android 8+, the system masks adaptive launcher icons to each device's
# shape. The 250px original star's paths sit within the adaptive safe zone.
vector("ic_launcher_foreground",108,108,250,"#FFFFFFFF",foreground,group="launcher")
vector("ic_launcher_monochrome",108,108,250,"#FF000000",foreground,group="launcher")
# Use the original Star brand SVG paths in both splash stages.
vector("splash_logo",85,85,286,"#FFFFFFFF",paths)
# Android 12+ system splash icon: white star safely centered on gold.
vector("splash_icon",288,288,288,"#FFFFFFFF",paths,group=True)
PY

# Render the original mark inset within the gold tile, then downsample for crisp
# legacy PNG icons. It includes the user's original gold rounded rectangle.
python3 - "$source_svg" "$work/padded.svg" <<'PYICON'
from pathlib import Path
import sys
from xml.etree import ElementTree as ET
p=ET.parse(sys.argv[1]); root=p.getroot()
ns="{http://www.w3.org/2000/svg}"
for item in list(root):
    if item.tag==ns+"path":
        root.remove(item)
        g=ET.SubElement(root,ns+"g",{"transform":"translate(27.5 27.5) scale(0.78)"})
        g.append(item)
p.write(sys.argv[2],encoding="unicode",xml_declaration=True)
PYICON
sips -s format png "$work/padded.svg" --out "$work/master.png" >/dev/null
for spec in "mdpi 48" "hdpi 72" "xhdpi 96" "xxhdpi 144" "xxxhdpi 192"; do
    read -r density dimension <<< "$spec"
    dir="$res/mipmap-$density"
    for name in ic_launcher.png ic_launcher_round.png; do
        sips -z "$dimension" "$dimension" "$work/master.png" --out "$dir/$name" >/dev/null
    done
done
sips -z 256 256 "$work/master.png" --out "$previews/default.png" >/dev/null
# Canary previews must display the same official design.
cp "$previews/default.png" "$previews/default_canary.png"
printf 'Android Star icons updated from original white-star-on-gold SVG.\n'
