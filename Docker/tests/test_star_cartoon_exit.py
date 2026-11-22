"""Regression checks for gold-to-white-star cartoon splash exit."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SHELL = ROOT / "Star mobile/lib/features/shell/presentation"
OVERLAY = SHELL / "splash_reveal_overlay.dart"
SPLASH = SHELL / "splash_screen.dart"


class StarCartoonExitTests(unittest.TestCase):
    def test_cartoon_exit_uses_real_star_svg_without_wordmark(self):
        source = OVERLAY.read_text()
        self.assertIn("useGoldCartoonTransition", source)
        self.assertIn("Assets.starSymbol", source)
        self.assertIn("ColorFilter.mode(", source)
        self.assertIn("Colors.white", source)
        self.assertNotIn("Assets.starLogoText", source)

    def test_gold_background_shrinks_to_rounded_circle(self):
        source = OVERLAY.read_text()
        self.assertIn("_GoldCartoonBackdropPainter", source)
        self.assertIn("RRect.fromRectAndRadius", source)
        self.assertIn("Color(0xFFD68F00)", source)
        self.assertIn("cartoonDuration", source)

    def test_white_star_bounces_then_disappears(self):
        source = OVERLAY.read_text()
        self.assertIn("Curves.bounceOut", source)
        self.assertIn("Curves.easeOutBack", source)
        self.assertIn("vanishProgress", source)
        self.assertIn("Opacity(opacity:", source)

    def test_unauthenticated_login_also_plays_gold_reveal(self):
        # Login is the initial route; the loading route is reserved for
        # authenticated accounts. The first login must show the same exit.
        source = OVERLAY.read_text()
        login = (ROOT / "Star mobile/lib/features/auth/presentation/login_screen.dart").read_text()
        self.assertIn("class StarGoldLaunchTransition", source)
        self.assertIn("StarGoldLaunchTransition(", login)
        self.assertIn("widget.child", source)
        self.assertIn("static bool _played", source)

    def test_reduce_motion_is_fade_only(self):
        source = OVERLAY.read_text()
        self.assertIn("reducedMotion", source)
        self.assertIn("if (widget.reducedMotion)", source)
        self.assertIn("reducedMotionDuration", source)

    def test_splash_uses_official_gold_background_on_mobile(self):
        source = SPLASH.read_text()
        self.assertIn("useGoldCartoonTransition:", source)
        self.assertIn("StarfieldSurface.brandGold", source)
        self.assertIn("Color(0xFFD68F00)", source)
        self.assertIn("Colors.white", source)
        self.assertIn("logoBrandSymbolColor: Colors.white", source)


if __name__ == "__main__":
    unittest.main()
