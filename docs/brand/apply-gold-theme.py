#!/usr/bin/env python3
"""Make Star's sign-in, loading screen and theme actions match the supplied brand."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "Star mobile"


def change(relative: str, old: str, new: str, count: int = 1) -> None:
    path = APP / relative
    text = path.read_text(encoding="utf-8")
    if text.count(old) != count:
        raise ValueError(f"{relative}: found {text.count(old)} copies, expected {count} of {old[:70]}")
    path.write_text(text.replace(old, new, count), encoding="utf-8")
    print("Updated:", relative)


# Android native launcher/splash -- the gold matches the supplied brand board.
change("android/app/src/main/res/values/colors.xml", "#080616", "#D68F00")
change("android/app/src/main/res/values/colors.xml", "#413CDD", "#D68F00")
change("android/app/src/main/res/values/ic_launcher_background.xml", "#4641D9", "#D68F00")
native_splash = APP / "android/app/src/main/res/drawable/launch_background.xml"
native_splash.write_text(
    '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Star: banner gold background + white star only, no wordmark. -->
    <item android:drawable="@color/launch_background"/>
    <item
        android:width="85dp"
        android:height="85dp"
        android:drawable="@drawable/splash_logo"
        android:gravity="center"/>
</layer-list>
''',
    encoding="utf-8",
)
print("Updated:", native_splash)

# Existing Android launch aliases may persist when users upgrade. Keep their
# registered names for compatibility, but do not display outdated app marks.
manifest = APP / "android/app/src/main/AndroidManifest.xml"
original = manifest.read_text(encoding="utf-8")
alias_count = 0
def unify_alias(match: re.Match[str]) -> str:
    global alias_count
    value = match.group(0)
    alias_count += 1
    return re.sub(r'android:icon="@mipmap/[^"]+"',
                  'android:icon="@mipmap/ic_launcher"', value)
updated = re.sub(r'<activity-alias\b[^>]*>', unify_alias, original, flags=re.S)
if alias_count < 8:
    raise ValueError(f"Expected old launcher variants, found {alias_count}")
manifest.write_text(updated, encoding="utf-8")
print(f"Unified {alias_count} icon aliases")

# Hide discontinued artwork from the icon picker. The aliases remain for
# previously selected icons but render the original Star mark.
p = APP / "lib/features/settings/domain/app_icon_catalog_android.dart"
s = p.read_text(encoding="utf-8")
needle = "List<AppIconChoice> androidAppIconChoiceCatalog() {"
if s.count(needle) != 1:
    raise ValueError("Android app icon catalog structure changed")
s = s[:s.index(needle)] + """List<AppIconChoice> androidAppIconChoiceCatalog() {
  // The only promoted icon is the supplied white-star-on-gold design.
  // Other Android activity aliases are kept for existing installations.
  return [
    AppIconChoice(
      alternateIconName: null,
      previewAssetPath: appIconPreviewAndroidDefault(),
      label: (StarLocalizations l10n) => l10n.appIconOptionDefault,
    ),
  ];
}
"""
p.write_text(s, encoding="utf-8")
print("Updated: Android app icon picker")

# Warm neutral backgrounds, brand actions and links; semantic error/success
# colors are not replaced with orange. The CSS/Electron client has its own
# theme system and is not automatically recolored by these Flutter changes.
for old,new in (
    ("neutralDark = ColorFamily(hue: 258, saturation: 10)",
     "neutralDark = ColorFamily(hue: 38, saturation: 9)"),
    ("neutralLight = ColorFamily(hue: 220, saturation: 10)",
     "neutralLight = ColorFamily(hue: 38, saturation: 6)"),
    ("brand = ColorFamily(hue: 242, saturation: 70)",
     "brand = ColorFamily(hue: 38, saturation: 100)"),
    ("link = ColorFamily(hue: 198, saturation: 92)",
     "link = ColorFamily(hue: 38, saturation: 95)"),
):
    change("lib/core/theme/color_families.dart", old,new)

for theme in ("light", "dark"):
    relative = f"lib/core/theme/themes/{theme}.dart"
    change(relative,
           "final brandPrimary = tone(StarColorFamilies.brand, 55);",
           "final brandPrimary = const Color(0xFF936000);")
    change(relative,
           "brandSecondary: tone(StarColorFamilies.brand, 49, saturation: 60),",
           "brandSecondary: const Color(0xFFB87A00),")
    change(relative,
           "brandPrimaryLight: toneDirect(hue: 242, saturation: 100, lightness: 84),",
           "brandPrimaryLight: const Color(0xFFEDD082),")
    change(relative,
           """buttonPrimaryFill: toneDirect(hue: 139, saturation: 55, lightness: 44),
    buttonPrimaryActiveFill: toneDirect(
      hue: 136,
      saturation: 60,
      lightness: 38,
    ),""",
           """buttonPrimaryFill: const Color(0xFF936000),
    buttonPrimaryActiveFill: const Color(0xFF704900),""")
    if theme == "light":
        change(relative,
               "backgroundPrimary: backgroundPrimary,",
               "backgroundPrimary: const Color(0xFFFFFFFF),")
        change(relative,
               "final textLink = tone(StarColorFamilies.link, 45);",
               "final textLink = const Color(0xFF936000);")
    else:
        change(relative,
               "final textLink = tone(StarColorFamilies.link, 70);",
               "final textLink = const Color(0xFFEDD082);")

# A color-decorative backdrop is used by several screens (including chat
# wallpaper); preserve the old appearance by default and opt in per surface.
background = "lib/features/ui/background/starfield_background.dart"
change(background, "class StarfieldBackdrop extends StatelessWidget {",
       """enum StarfieldSurface { night, light, brandGold }

class StarfieldBackdrop extends StatelessWidget {""")
change(background,
       "const StarfieldBackdrop({this.child, super.key});",
       """const StarfieldBackdrop({
    this.child,
    this.surface = StarfieldSurface.night,
    super.key,
  });""")
change(background,
       """  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(""",
       """  final Widget? child;
  final StarfieldSurface surface;

  @override
  Widget build(BuildContext context) {
    if (surface == StarfieldSurface.brandGold) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFD68F00)),
          if (child != null) Positioned.fill(child: child!),
        ],
      );
    }
    if (surface == StarfieldSurface.light) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFFFFFFFF)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.7),
                radius: 1.5,
                colors: [Color(0x0EEDD082), Color(0x00EDD082)],
              ),
            ),
          ),
          if (child != null) Positioned.fill(child: child!),
        ],
      );
    }
    return Stack(""")
change(background,
       "const StarfieldBackground({this.child, this.animate = true, super.key});",
       """const StarfieldBackground({
    this.child,
    this.animate = true,
    this.surface = StarfieldSurface.night,
    super.key,
  });""")
change(background,
       """  final Widget? child;
  final bool animate;

  @override
  State<StarfieldBackground> createState()""",
       """  final Widget? child;
  final bool animate;
  final StarfieldSurface surface;

  @override
  State<StarfieldBackground> createState()""")
change(background,
       """    return StarfieldBackdrop(
      child: Stack(""",
       """    return StarfieldBackdrop(
      surface: widget.surface,
      child: Stack(""")
change(background,
       """                      parallaxOffset: Offset(
                        _quantizePixels(
                          _parallaxOffset.value.dx * motionIntensity,
                        ),
                        _quantizePixels(
                          _parallaxOffset.value.dy * motionIntensity,
                        ),
                      ),
                    ),""",
       """                      parallaxOffset: Offset(
                        _quantizePixels(
                          _parallaxOffset.value.dx * motionIntensity,
                        ),
                        _quantizePixels(
                          _parallaxOffset.value.dy * motionIntensity,
                        ),
                      ),
                      surface: widget.surface,
                    ),""")
change(background,
       """    required this.parallaxOffset,
  });

  final double fineProgress;""",
       """    required this.parallaxOffset,
    required this.surface,
  });

  final StarfieldSurface surface;
  final double fineProgress;""")
change(background,
       """      paint
        ..color = star.color
        ..maskFilter = glow;""",
       """      final Color starColor = switch (surface) {
        StarfieldSurface.night => star.color,
        StarfieldSurface.light => const Color(0xFFB87A00).withValues(
          alpha: star.color.a * 0.23,
        ),
        StarfieldSurface.brandGold => Colors.white.withValues(
          alpha: star.color.a * 0.50,
        ),
      };
      paint
        ..color = starColor
        ..maskFilter = glow;""")
change(background,
       """        oldDelegate.parallaxOffset != parallaxOffset;""",
       """        oldDelegate.parallaxOffset != parallaxOffset ||
        oldDelegate.surface != surface;""")

# Ensure the login remains light even if a previous signed-in session selected
# dark mode. Do not overwrite that saved preference or authenticated screens.
login = "lib/features/auth/presentation/login_screen.dart"
change(login,
       "import 'package:flutter_riverpod/flutter_riverpod.dart';",
       """import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';""")
change(login,
       "import 'package:star_app/core/theme/star_theme_extension.dart';",
       """import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/core/theme/themes/light.dart';""")
change(login,
       """    if (isMobile) {
      return _buildMobileLayout(context, ref);
    }
    return _buildDesktopLayout(context, ref);""",
       """    final lightTheme = cachedStarTheme(
      colorTheme: buildLightColorTheme(),
      brightness: Brightness.light,
    );
    return Theme(
      data: lightTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: starSystemUiOverlayStyle(
          brightness: Brightness.light,
          navigationBarColor: Colors.white,
        ),
        child: Builder(
          builder: (lightContext) => isMobile
              ? _buildMobileLayout(lightContext, ref)
              : _buildDesktopLayout(lightContext, ref),
        ),
      ),
    );""")
change(login,
       "body: StarfieldBackground(",
       "body: StarfieldBackground(surface: StarfieldSurface.light,", count=2)

print("Star Android native assets, login and shared Flutter color tokens updated")
