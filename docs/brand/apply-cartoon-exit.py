#!/usr/bin/env python3
"""Gold cover -> circular badge -> bouncing white Star -> reveal next route."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DIR = ROOT / "Star mobile/lib/features/shell/presentation"


def edit(name, old, new, count=1):
    path=DIR/name
    text=path.read_text(encoding="utf-8")
    if text.count(old)!=count:
        raise ValueError(f"{name}: found {text.count(old)} not {count} for: {old[:75]}")
    path.write_text(text.replace(old,new,count), encoding="utf-8")
    print("Updated",name)


overlay = "splash_reveal_overlay.dart"
edit(overlay,"import 'dart:async';","import 'dart:async';\nimport 'dart:math' as math;")
edit(overlay,"import 'package:flutter/scheduler.dart';",
     """import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_app/core/constants/assets.dart';""")
edit(overlay,"static const Duration totalDuration = Duration(milliseconds: 800);",
     """static const Duration totalDuration = Duration(milliseconds: 800);
  static const Duration cartoonDuration = Duration(milliseconds: 980);""")
edit(overlay,
     """    required bool useLogoZoomTransition,
    VoidCallback? onComplete,""",
     """    required bool useLogoZoomTransition,
    bool useGoldCartoonTransition = false,
    VoidCallback? onComplete,""")
edit(overlay,
     """    final Duration revealDuration = !enabled
        ? SplashRevealOverlay.reducedMotionDuration
        : useLogoZoomTransition
        ? SplashRevealOverlay.totalDuration
        : SplashRevealOverlay.fadeOnlyDuration;""",
     """    final Duration revealDuration = !enabled
        ? SplashRevealOverlay.reducedMotionDuration
        : useGoldCartoonTransition
        ? SplashRevealOverlay.cartoonDuration
        : useLogoZoomTransition
        ? SplashRevealOverlay.totalDuration
        : SplashRevealOverlay.fadeOnlyDuration;""")
edit(overlay,
     """          useLogoZoomTransition: useLogoZoomTransition,
          reducedMotion: !enabled,""",
     """          useLogoZoomTransition: useLogoZoomTransition,
          useGoldCartoonTransition: useGoldCartoonTransition,
          reducedMotion: !enabled,""")
edit(overlay,
     """    required this.useLogoZoomTransition,
    required this.reducedMotion,""",
     """    required this.useLogoZoomTransition,
    required this.useGoldCartoonTransition,
    required this.reducedMotion,""")
edit(overlay,
     """  final bool useLogoZoomTransition;
  final bool reducedMotion;""",
     """  final bool useLogoZoomTransition;
  final bool useGoldCartoonTransition;
  final bool reducedMotion;""")
edit(overlay,
     """    if (!widget.useLogoZoomTransition) {
      return SplashRevealOverlay.fadeOnlyDuration;
    }""",
     """    if (widget.useGoldCartoonTransition) {
      return SplashRevealOverlay.cartoonDuration;
    }
    if (!widget.useLogoZoomTransition) {
      return SplashRevealOverlay.fadeOnlyDuration;
    }""")
needle="""  @override
  Widget build(BuildContext context) {
    final Offset center = _localCenter();
    final bool expandPhase = _isExpandPhase();"""
replace="""  // The exit cover starts as the full banner-gold screen, shrinks smoothly
  // into a circular badge around the authentic white SVG, then bounces once
  // and dissolves. This is an opt-in path; desktop legacy reveal is preserved.
  Widget _buildGoldCartoonExit(BuildContext context) {
    final Offset center = _localCenter();
    const double iconSize = SplashRevealOverlay.logoSize;
    final double vanishProgress = Curves.easeInCubic.transform(
      ((_progress - 0.84) / 0.16).clamp(0.0, 1.0),
    );

    // Accessible reduced-motion behavior: no scaling, bouncing, or movement.
    if (widget.reducedMotion) {
      return ExcludeSemantics(
        child: IgnorePointer(
          child: Opacity(
            opacity: 1 - Curves.easeOut.transform(_progress),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFD68F00)),
                Positioned(
                  left: center.dx - iconSize / 2,
                  top: center.dy - iconSize / 2,
                  width: iconSize,
                  height: iconSize,
                  child: SvgPicture.asset(
                    Assets.starSymbol,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double bounceProgress = ((_progress - 0.58) / 0.25).clamp(
      0.0,
      1.0,
    );
    final double starScale;
    if (_progress < 0.58) {
      starScale = 1;
    } else if (_progress < 0.70) {
      starScale = lerpDouble(
        1,
        1.17,
        Curves.easeOutBack.transform(
          ((_progress - 0.58) / 0.12).clamp(0.0, 1.0),
        ),
      )!;
    } else if (_progress < 0.84) {
      starScale = lerpDouble(
        1.17,
        0.92,
        Curves.bounceOut.transform(
          ((_progress - 0.70) / 0.14).clamp(0.0, 1.0),
        ),
      )!;
    } else {
      starScale = 0.92 * (1 - vanishProgress);
    }
    final double hop = -20 *
        math.sin(math.pi * bounceProgress) *
        (1 - bounceProgress);

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _GoldCartoonBackdropPainter(
                progress: _progress,
                logoCenter: center,
              ),
            ),
            Positioned(
              left: center.dx - iconSize / 2,
              top: center.dy - iconSize / 2,
              width: iconSize,
              height: iconSize,
              child: Opacity(opacity: 1 - vanishProgress,
                child: Transform.translate(
                  offset: Offset(0, hop),
                  child: Transform.scale(
                    scale: starScale,
                    child: SvgPicture.asset(
                      Assets.starSymbol,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useGoldCartoonTransition) {
      return _buildGoldCartoonExit(context);
    }
    final Offset center = _localCenter();
    final bool expandPhase = _isExpandPhase();"""
edit(overlay,needle,replace)
# Keep paint geometry co-located with animation and avoid a large full-screen
# opaque widget that could delay the route reveal during shrink.
anchor="class _SplashRevealPainter extends CustomPainter {"
new="""class _GoldCartoonBackdropPainter extends CustomPainter {
  _GoldCartoonBackdropPainter({
    required this.progress,
    required this.logoCenter,
  });

  final double progress;
  final Offset logoCenter;

  @override
  void paint(Canvas canvas, Size size) {
    final double shrink = Curves.easeInOutCubic.transform(
      (progress / 0.58).clamp(0.0, 1.0),
    );
    final double vanish = Curves.easeInCubic.transform(
      ((progress - 0.84) / 0.16).clamp(0.0, 1.0),
    );
    final Offset center = Offset.lerp(
      size.center(Offset.zero),
      logoCenter,
      shrink,
    )!;
    const double badgeDiameter = 116;
    final double exitScale = lerpDouble(1, 0.18, vanish)!;
    final double width =
        lerpDouble(size.width, badgeDiameter, shrink)! * exitScale;
    final double height =
        lerpDouble(size.height, badgeDiameter, shrink)! * exitScale;
    final Rect box = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    final double cornerRadius = math.min(width, height) * 0.5 * shrink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(cornerRadius)),
      Paint()
        ..color = const Color(0xFFD68F00).withValues(alpha: 1 - vanish)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldCartoonBackdropPainter old) =>
      old.progress != progress || old.logoCenter != logoCenter;
}

class _SplashRevealPainter extends CustomPainter {"""
edit(overlay,anchor,new)

splash="splash_screen.dart"
edit(splash,
     "import 'package:star_app/core/theme/color_utils.dart';\n","")
edit(splash,
     "import 'package:star_app/features/ui/icons/instance_branding_image.dart';",
     "import 'package:star_app/features/ui/icons/star_brand_logo.dart';")
edit(splash,
     """  static const Color _splashMutedText = Color(0xFF9B94B8);
  static const Color _splashLinkText = Color(0xFFC4B8F0);
  static const Color _splashQuoteText = Color(0xFFD6D0EC);""",
     """  static const Color _splashMutedText = Color(0xFFFCE9BA);
  static const Color _splashLinkText = Colors.white;
  static const Color _splashQuoteText = Colors.white;""")
edit(splash,
     """    final Color brand = context.colors.brandPrimary;
    SplashRevealOverlay.show(""",
     """    const Color brand = Color(0xFFD68F00);
    SplashRevealOverlay.show(""")
edit(splash,
     """      logoBrandSymbolColor: ColorUtils.bestContrastColor(brand.toARGB32()),""",
     """      logoBrandSymbolColor: Colors.white,""")
edit(splash,
     """      useLogoZoomTransition: useLogoZoomTransition,
      animationsEnabled:""",
     """      useLogoZoomTransition: useLogoZoomTransition,
      useGoldCartoonTransition: true,
      animationsEnabled:""")
edit(splash,
     """      body: StarfieldBackground(
        child: Stack(""",
     """      body: StarfieldBackground(
        surface: StarfieldSurface.brandGold,
        child: Stack(""")
edit(splash,
     """                            child: InstanceBrandMark(
                              size: _logoHeight,
                              backgroundColor: context.colors.brandPrimary,
                            ),""",
     """                            child: const StarBrandLogo(
                              size: _logoHeight,
                              backgroundColor: Color(0xFFD68F00),
                              symbolColor: Colors.white,
                            ),""")
print("Cartoon exit and white-star gold splash applied")
