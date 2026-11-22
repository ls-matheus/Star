"""Regression gates for user-supplied Star Android launcher, splash, and light UI."""
from pathlib import Path
import re
import struct
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "Star mobile"
RES = APP / "android/app/src/main/res"
ANDROID = "{http://schemas.android.com/apk/res/android}"
SVG = "{http://www.w3.org/2000/svg}"

class AndroidBrandRefreshTests(unittest.TestCase):
    def test_adaptive_icons_use_original_star_paths(self):
        original = ET.parse(
            ROOT / "docs/brand/sources/star-app-icon-original.svg"
        ).getroot()
        symbol = ET.parse(
            ROOT / "docs/brand/sources/star-symbol-original.svg"
        ).getroot()
        launch_paths = [p.attrib["d"] for p in original.iter(SVG + "path")]
        splash_paths = [p.attrib["d"] for p in symbol.iter(SVG + "path")]
        for resource in ("ic_launcher_foreground", "ic_launcher_monochrome", "splash_logo", "splash_icon"):
            with self.subTest(resource=resource):
                expected = launch_paths if resource.startswith("ic_launcher") else splash_paths
                xml = ET.parse(RES / "drawable" / f"{resource}.xml").getroot()
                found = [p.attrib[ANDROID+"pathData"] for p in xml.iter("path")]
                self.assertEqual(found, expected)

    def test_launcher_and_legacy_pngs_have_official_gold_palette(self):
        colors = (RES / "values/ic_launcher_background.xml").read_text()
        self.assertIn("#D68F00", colors)
        for density, expected in (
            ("mdpi",48), ("hdpi",72), ("xhdpi",96),
            ("xxhdpi",144), ("xxxhdpi",192)
        ):
            for name in ("ic_launcher.png", "ic_launcher_round.png"):
                p = RES / f"mipmap-{density}" / name
                self.assertTrue(p.exists(),str(p))
                data=p.read_bytes()
                self.assertEqual(data[:8],b"\x89PNG\r\n\x1a\n")
                w,h=struct.unpack(">II",data[16:24])
                self.assertEqual((w,h),(expected,expected))

    def test_canary_preview_matches_primary_gold_icon(self):
        previews = APP / "assets/images/app_icon_previews/android"
        self.assertEqual(
            (previews / "default.png").read_bytes(),
            (previews / "default_canary.png").read_bytes(),
        )

    def test_splash_symbol_is_white_on_banner_gold(self):
        for name in ("splash_icon", "splash_logo"):
            root = ET.parse(RES / "drawable" / f"{name}.xml").getroot()
            fills = [
                path.attrib[ANDROID + "fillColor"]
                for path in root.iter("path")
            ]
            self.assertEqual(fills, ["#FFFFFFFF", "#FFFFFFFF"])
        background = (RES / "values/colors.xml").read_text()
        self.assertIn('<color name="launch_background">#D68F00</color>', background)

    def test_previous_icon_aliases_do_not_restore_purple_logos(self):
        manifest = (APP / "android/app/src/main/AndroidManifest.xml").read_text()
        alias_icons = re.findall(
            r"<activity-alias\s+[^>]*?android:icon=\"([^\"]+)\"",
            manifest, re.S
        )
        self.assertGreaterEqual(len(alias_icons), 8)
        self.assertTrue(all(icon=="@mipmap/ic_launcher" for icon in alias_icons))

    def test_android_launch_is_banner_gold_and_has_no_old_wave(self):
        colors=(RES/"values/colors.xml").read_text()
        self.assertIn('#D68F00',colors)
        self.assertIn('#FFFFFF',colors)
        self.assertNotIn('#413CDD',colors)
        startup=(RES/"drawable/launch_background.xml").read_text()
        self.assertIn('@color/launch_background',startup)
        self.assertNotIn('@drawable/splash_starfield',startup)

    def test_login_uses_light_gold_theme_and_starfield(self):
        login=(APP/"lib/features/auth/presentation/login_screen.dart").read_text()
        self.assertIn('StarfieldSurface.light',login)
        self.assertIn('cachedStarTheme(',login)
        self.assertIn('Brightness.light',login)
        colors=(APP/"lib/core/theme/color_families.dart").read_text()
        self.assertIn('ColorFamily(hue: 38, saturation:',colors)
        for theme in ('light','dark'):
            p=APP/f"lib/core/theme/themes/{theme}.dart"
            txt=p.read_text()
            self.assertIn('Color(0xFFB87A00)',txt)
            self.assertIn('Color(0xFF936000)',txt)
        background=(APP/"lib/features/ui/background/starfield_background.dart").read_text()
        self.assertIn('StarfieldSurface.light',background)
        self.assertIn('Color(0xFFFFFFFF)',background)

    def test_applied_star_has_no_branded_flutter_launcher(self):
        # The Flutter SDK remains part of the application; it must not be
        # confused with an authorization to use third-party visual marks.
        source=(APP/"lib/features/ui/icons/star_brand_logo.dart").read_text()
        self.assertIn('Assets.starSymbol',source)

if __name__=="__main__":
    unittest.main()
