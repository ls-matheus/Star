"""Ensure user-supplied Star logotype is faithfully preserved across platforms."""

import sys
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BRAND_DIR = ROOT / "docs/brand"
sys.path.insert(0, str(BRAND_DIR))

import generate as brand  # noqa: E402


class StarBrandIdentityTests(unittest.TestCase):
    def test_user_wordmark_uses_original_vector_outlines(self):
        expected = [
            path.attrib["d"]
            for path in brand.paths("star-wordmark-original.svg")
        ]
        self.assertEqual(len(expected), 1)
        for rel in (
            "docs/brand/star-wordmark-white.svg",
            "docs/brand/star-logo-horizontal-white.svg",
            "Star mobile/assets/images/star-logo-wordmark-monochrome.svg",
            "Star mobile/assets/images/star-logo-text.svg",
            "Star web/star_app/src/media/images/star-logo-wordmark-monochrome.svg",
            "Star Server/star_app/src/media/images/star-logo-wordmark-monochrome.svg",
        ):
            root = ET.parse(ROOT / rel).getroot()
            actual = [path.attrib["d"] for path in root.iter(brand.tag("path"))]
            self.assertIn(expected[0], actual, rel)

    def test_all_generated_assets_match_the_source_of_truth(self):
        for rel, expected in brand.OUTPUTS.items():
            with self.subTest(asset=rel):
                actual = ET.parse(ROOT / rel).getroot()
                self.assertEqual(
                    ET.tostring(actual),
                    ET.tostring(expected),
                    rel,
                )

    def test_brand_icon_is_exact_user_supplied_svg(self):
        root = ET.parse(BRAND_DIR / "sources/star-app-icon-original.svg").getroot()
        rects = list(root.iter(brand.tag("rect")))
        self.assertEqual(len(rects), 1)
        self.assertEqual(rects[0].get("fill"), brand.GOLD)
        self.assertEqual(len(list(root.iter(brand.tag("path")))), 2)

    def test_font_license_is_identified_without_bundling_fonts(self):
        readme = (BRAND_DIR / "README.md").read_text(encoding="utf-8")
        self.assertIn("Cherry Bomb One", readme)
        self.assertIn("SIL Open Font License 1.1", readme)
        self.assertIn("already converted to vector paths", readme)
        self.assertFalse(list(BRAND_DIR.rglob("*.ttf")))
        self.assertFalse(list(BRAND_DIR.rglob("*.otf")))


if __name__ == "__main__":
    unittest.main()
