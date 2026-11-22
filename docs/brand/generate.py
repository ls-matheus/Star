#!/usr/bin/env python3
"""Generate Star vector branding from user-supplied source artwork.

The glyphs in star-wordmark-original.svg were converted to paths by the
designer. This tool does not substitute or approximate the Cherry Bomb One font.
"""
from __future__ import annotations

from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
BRAND = Path(__file__).resolve().parent
SOURCES = BRAND / "sources"
NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", NS)

GOLD = "#D68F00"
WHITE = "#FFFFFF"
CREAM = "#EDD082"


def tag(name: str) -> str:
    return f"{{{NS}}}{name}"


def paths(name: str) -> list[ET.Element]:
    root = ET.parse(SOURCES / name).getroot()
    result = list(root.iter(tag("path")))
    if not result:
        raise ValueError(f"Source contains no vector paths: {name}")
    return result


def svg(viewbox: str, width: str, height: str) -> ET.Element:
    return ET.Element(tag("svg"), {"viewBox": viewbox, "width": width, "height": height})


def add_paths(root: ET.Element, name: str, color: str, transform: str | None = None) -> None:
    parent = ET.SubElement(root, tag("g"), {"transform": transform}) if transform else root
    for source_path in paths(name):
        new_path = ET.SubElement(parent, tag("path"), source_path.attrib.copy())
        new_path.set("fill", color)


def symbol(color: str) -> ET.Element:
    root = svg("0 0 286 272", "286", "272")
    add_paths(root, "star-symbol-original.svg", color)
    return root


def wordmark(color: str) -> ET.Element:
    root = svg("0 0 64 31", "64", "31")
    add_paths(root, "star-wordmark-original.svg", color)
    return root


def horizontal(color: str) -> ET.Element:
    root = svg("0 0 376 122", "376", "122")
    add_paths(root, "star-symbol-original.svg", color, "translate(21 10) scale(0.38)")
    add_paths(root, "star-wordmark-original.svg", color, "translate(166 21) scale(2.95)")
    return root


def badge() -> ET.Element:
    root = svg("0 0 392 150", "392", "150")
    ET.SubElement(root, tag("rect"), {"width": "392", "height": "150", "rx": "36", "fill": GOLD})
    add_paths(root, "star-symbol-original.svg", WHITE, "translate(21 23) scale(0.38)")
    add_paths(root, "star-wordmark-original.svg", WHITE, "translate(166 33) scale(2.95)")
    return root


OUTPUTS = {
    "docs/brand/star-symbol-gold.svg": symbol(GOLD),
    "docs/brand/star-symbol-cream.svg": symbol(CREAM),
    "docs/brand/star-symbol-white.svg": symbol(WHITE),
    "docs/brand/star-wordmark-white.svg": wordmark(WHITE),
    "docs/brand/star-wordmark-gold.svg": wordmark(GOLD),
    "docs/brand/star-logo-horizontal-gold.svg": horizontal(GOLD),
    "docs/brand/star-logo-horizontal-white.svg": horizontal(WHITE),
    "docs/brand/star-logo-badge.svg": badge(),
    "Star mobile/assets/images/star-symbol.svg": symbol(GOLD),
    "Star mobile/assets/images/star-logo-monochrome.svg": symbol(WHITE),
    "Star mobile/assets/images/star-logo-text.svg": horizontal(GOLD),
    "Star mobile/assets/images/star-logo-wordmark-monochrome.svg": horizontal(WHITE),
    "Star web/star_app/src/media/images/star-logo-color.svg": symbol(GOLD),
    "Star web/star_app/src/media/images/star-logo-wordmark-monochrome.svg": horizontal(WHITE),
    "Star Server/star_app/src/media/images/star-logo-color.svg": symbol(GOLD),
    "Star Server/star_app/src/media/images/star-logo-wordmark-monochrome.svg": horizontal(WHITE),
    "Star web/star_admin/static/star-logo-color.svg": symbol(GOLD),
    "Star Server/star_admin/static/star-logo-color.svg": symbol(GOLD),
    "Star web/star_static/marketing/branding/logo-color.svg": symbol(GOLD),
    "Star web/star_static/marketing/branding/logo-white.svg": symbol(WHITE),
    "Star Server/star_static/marketing/branding/logo-color.svg": symbol(GOLD),
    "Star Server/star_static/marketing/branding/logo-white.svg": symbol(WHITE),
}


def main() -> None:
    for relative_path, root in OUTPUTS.items():
        target = ROOT / relative_path
        if not target.parent.is_dir():
            raise FileNotFoundError(f"Missing target directory: {target.parent}")
        target.write_bytes(ET.tostring(root, encoding="utf-8", xml_declaration=False))
        print(f"Updated {relative_path}")


if __name__ == "__main__":
    main()
