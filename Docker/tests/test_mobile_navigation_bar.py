"""Regression checks for Android transparent navigation and system UI restoration."""

from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
MOBILE = ROOT / "Star mobile/lib"


class AndroidNavigationBarTests(unittest.TestCase):
    def test_bootstrap_requests_edge_to_edge_for_android(self):
        source = (MOBILE / "main.dart").read_text(encoding="utf-8")
        self.assertRegex(
            source,
            r"if \(Platform\.isAndroid\) \{\s*"
            r"(?://[^\n]*\n\s*)*"
            r"await SystemChrome\.setEnabledSystemUIMode\("
            r"SystemUiMode\.edgeToEdge\)",
        )

    def test_navigation_bar_is_transparent_with_adaptive_icons(self):
        source = (MOBILE / "core/theme/star_theme.dart").read_text(
            encoding="utf-8"
        )
        self.assertIn("systemNavigationBarColor:", source)
        self.assertRegex(
            source, r"systemNavigationBarColor:\s*"
            r"isStarNativeAndroid\s*\?\s*const Color\(0x00000000\)",
        )
        self.assertIn("systemNavigationBarIconBrightness: iconBrightness", source)
        self.assertIn("systemNavigationBarContrastEnforced: false", source)

    def test_navigation_bar_has_themed_background_to_show_through(self):
        source = (MOBILE / "app.dart").read_text(encoding="utf-8")
        self.assertRegex(
            source,
            r"isStarNativeAndroid\s*\?\s*ColoredBox\("
            r"\s*color: materialTheme\.scaffoldBackgroundColor",
        )

    def test_voice_calls_restore_edge_to_edge(self):
        source = (
            MOBILE / "features/ui/voice/voice_call_system_ui_sync.dart"
        ).read_text(encoding="utf-8")
        self.assertIn("SystemUiMode.edgeToEdge", source)
        self.assertIn("_showSystemBars", source)


if __name__ == "__main__":
    unittest.main()
