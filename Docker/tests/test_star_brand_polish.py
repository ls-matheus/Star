"""Regression checks for Star's requested Mac and mobile visual identity."""

from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


class StarVisualPolishTests(unittest.TestCase):
    def test_readme_uses_gold_logo(self):
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("docs/brand/star-logo-horizontal-gold.svg", readme)

    def test_mobile_brand_font_registered_with_notice(self):
        pubspec = (ROOT / "Star mobile/pubspec.yaml").read_text(encoding="utf-8")
        self.assertIn("family: CherryBombOne", pubspec)
        self.assertIn("assets/fonts/CherryBombOne-Regular.ttf", pubspec)
        self.assertTrue((ROOT / "Star mobile/assets/fonts/CherryBombOne-Regular.ttf").is_file())
        self.assertTrue((ROOT / "Star mobile/assets/fonts/OFL-CherryBombOne.txt").is_file())

    def test_mobile_brand_headers_use_cherry_bomb_but_messages_remain_legible(self):
        fonts = (ROOT / "Star mobile/lib/core/theme/star_fonts.dart").read_text(encoding="utf-8")
        theme = (ROOT / "Star mobile/lib/core/theme/star_text_theme.dart").read_text(encoding="utf-8")
        self.assertIn("static const String brand = 'CherryBombOne';", fonts)
        heading = theme.split("heading: TextStyle(", 1)[1].split("),", 1)[0]
        message = theme.split("messageText: TextStyle(", 1)[1].split("),", 1)[0]
        self.assertIn("StarFonts.brand", heading)
        self.assertIn("StarFonts.sans", message)
        fallback = (ROOT / "Star mobile/lib/features/ui/icons/instance_branding_image.dart").read_text(encoding="utf-8")
        self.assertIn("Assets.starLogoText", fallback)

    def test_mac_window_header_is_unbranded_but_other_platforms_keep_brand(self):
        for component in ("Star web", "Star Server"):
            shell = (ROOT / component / "packages/desktop_ipc/src/NativeTitlebarShell.ts").read_text(encoding="utf-8")
            renderer = (ROOT / component / "star_app/src/features/app/components/layout/NativeTitlebar.tsx").read_text(encoding="utf-8")
            self.assertRegex(shell, r"if \(layout === 'macos'\) \{\s*return spacer;")
            mac_branch = renderer.split("{isMacOS ? (", 1)[1].split(") : (", 1)[0]
            self.assertNotIn("{brand}", mac_branch)
            other_branch = renderer.split(") : (", 1)[1]
            self.assertIn("{brand}", other_branch)

    def test_flutter_macos_window_bar_has_no_visible_wordmark(self):
        source = (ROOT / "Star mobile/lib/features/shell/presentation/native_titlebar.dart").read_text(encoding="utf-8")
        mac = source.split("children: isMacOS", 1)[1].split(": const [", 1)[0]
        self.assertNotIn("_Wordmark()", mac)
        self.assertIn("Spacer()", mac)
        self.assertIn("_Wordmark()", source.split(": const [", 1)[1])

    def test_macos_icon_is_branded_and_stable_channels_match(self):
        icons = []
        for component in ("Star web", "Star Server"):
            icon = ROOT / component / "star_desktop/build_resources/icons-stable/_compiled/AppIcon.icns"
            data = icon.read_bytes()
            self.assertEqual(data[:4], b"icns")
            self.assertGreater(len(data), 4096)
            icons.append(data)
        self.assertEqual(icons[0], icons[1])


if __name__ == "__main__":
    unittest.main()
