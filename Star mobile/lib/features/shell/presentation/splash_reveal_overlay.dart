import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:star_app/core/constants/assets.dart';
import 'package:star_app/core/theme/color_utils.dart';
import 'package:star_app/features/ui/background/starfield_background.dart';
import 'package:star_app/features/ui/icons/instance_branding_image.dart';
import 'package:star_app/material_ui.dart';

class SplashRevealOverlay {
  SplashRevealOverlay._();

  static const double logoSize = 85;
  static const double pulseScale = 0.8;
  static const double expandScale = 500;
  static const double pulseEndFraction = 0.08;
  static const double shellStartScale = 1.1;
  static const double symbolViewBox = 512;
  static const Duration totalDuration = Duration(milliseconds: 800);
  static const Duration cartoonDuration = Duration(milliseconds: 1650);
  static const Duration fadeOnlyDuration = Duration(milliseconds: 350);
  static const Duration reducedMotionDuration = Duration(milliseconds: 300);
  static const int maxTickMicros = 32000;

  static final Color silhouetteSymbolColor = ColorUtils.dim(
    StarfieldBackground.cutoutSymbolColor,
    0.3,
  );

  static void show({
    required BuildContext context,
    required Color coverColor,
    required Color logoBrandColor,
    required Color logoBrandSymbolColor,
    required Offset logoCenterGlobal,
    required bool useLogoZoomTransition,
    bool useGoldCartoonTransition = false,
    VoidCallback? onComplete,
    bool? animationsEnabled,
  }) {
    final bool enabled =
        animationsEnabled ?? !MediaQuery.disableAnimationsOf(context);

    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    var finished = false;
    Timer? failsafe;
    void finish() {
      if (finished) {
        return;
      }
      finished = true;
      failsafe?.cancel();
      failsafe = null;
      if (entry.mounted) {
        entry.remove();
      }
      onComplete?.call();
    }

    final Duration revealDuration = !enabled
        ? SplashRevealOverlay.reducedMotionDuration
        : useGoldCartoonTransition
        ? SplashRevealOverlay.cartoonDuration
        : useLogoZoomTransition
        ? SplashRevealOverlay.totalDuration
        : SplashRevealOverlay.fadeOnlyDuration;
    entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return _SplashRevealOverlayWidget(
          coverColor: coverColor,
          logoBrandColor: logoBrandColor,
          logoBrandSymbolColor: logoBrandSymbolColor,
          logoCenterGlobal: logoCenterGlobal,
          useLogoZoomTransition: useLogoZoomTransition,
          useGoldCartoonTransition: useGoldCartoonTransition,
          reducedMotion: !enabled,
          onComplete: finish,
          onDispose: () {
            failsafe?.cancel();
            failsafe = null;
          },
        );
      },
    );
    overlay.insert(entry);
    failsafe = Timer(
      revealDuration + const Duration(milliseconds: 400),
      finish,
    );
  }
}

class _SplashRevealOverlayWidget extends StatefulWidget {
  const _SplashRevealOverlayWidget({
    required this.coverColor,
    required this.logoBrandColor,
    required this.logoBrandSymbolColor,
    required this.logoCenterGlobal,
    required this.useLogoZoomTransition,
    required this.useGoldCartoonTransition,
    required this.reducedMotion,
    required this.onComplete,
    this.onDispose,
  });

  final Color coverColor;
  final Color logoBrandColor;
  final Color logoBrandSymbolColor;
  final Offset logoCenterGlobal;
  final bool useLogoZoomTransition;
  final bool useGoldCartoonTransition;
  final bool reducedMotion;
  final VoidCallback onComplete;
  final VoidCallback? onDispose;

  @override
  State<_SplashRevealOverlayWidget> createState() =>
      _SplashRevealOverlayWidgetState();
}

class _SplashRevealOverlayWidgetState extends State<_SplashRevealOverlayWidget>
    with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double _progress = 0;

  Duration get _duration {
    if (widget.reducedMotion) {
      return SplashRevealOverlay.reducedMotionDuration;
    }
    if (widget.useGoldCartoonTransition) {
      return SplashRevealOverlay.cartoonDuration;
    }
    if (!widget.useLogoZoomTransition) {
      return SplashRevealOverlay.fadeOnlyDuration;
    }
    return SplashRevealOverlay.totalDuration;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ticker != null) {
        return;
      }
      _ticker = createTicker(_onTick);
      _ticker!.start();
    });
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    _ticker?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) {
      return;
    }
    final int dt = (elapsed - _lastElapsed).inMicroseconds.clamp(
      0,
      SplashRevealOverlay.maxTickMicros,
    );
    _lastElapsed = elapsed;

    final double next = (_progress + dt / _duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );

    setState(() => _progress = next);
    if (next >= 1) {
      _ticker?.stop();
      widget.onComplete();
    }
  }

  bool _isExpandPhase() {
    if (widget.reducedMotion || !widget.useLogoZoomTransition) {
      return false;
    }
    return _progress > SplashRevealOverlay.pulseEndFraction;
  }

  Offset _localCenter() {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return widget.logoCenterGlobal;
    }
    return renderObject.globalToLocal(widget.logoCenterGlobal);
  }

  static const Widget _starfield = RepaintBoundary(
    child: StarfieldBackground(animate: false),
  );

  ({Color fill, Color symbol}) _logoColors(double t) {
    final Color fill = Color.lerp(widget.logoBrandColor, widget.coverColor, t)!;
    final Color symbol = Color.lerp(
      widget.logoBrandSymbolColor,
      SplashRevealOverlay.silhouetteSymbolColor,
      t,
    )!;
    return (fill: fill, symbol: symbol);
  }

  // The exit cover starts as the full banner-gold screen, shrinks smoothly
  // into a circular badge around the authentic white SVG, then bounces once
  // and dissolves. This is an opt-in path; desktop legacy reveal is preserved.

  @override
  Widget build(BuildContext context) {
    if (widget.useGoldCartoonTransition) {
      return _buildGoldCartoonFrame(
        progress: _progress,
        center: _localCenter(),
        reducedMotion: widget.reducedMotion,
      );
    }
    final Offset center = _localCenter();
    final bool expandPhase = _isExpandPhase();
    final double scale = splashRevealLogoScale(
      _progress,
      reducedMotion: widget.reducedMotion,
      useLogoZoomTransition: widget.useLogoZoomTransition,
    );
    final double coverOpacity = splashRevealLayerOpacity(
      _progress,
      reducedMotion: widget.reducedMotion,
    );

    if (coverOpacity <= 0) {
      return const ExcludeSemantics(child: IgnorePointer());
    }

    if (expandPhase) {
      return ExcludeSemantics(
        child: IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: coverOpacity, child: _starfield),
              CustomPaint(
                painter: _SplashRevealPainter(
                  symbolColor: SplashRevealOverlay.silhouetteSymbolColor,
                  center: center,
                  scale: scale,
                  symbolOpacity: splashRevealSymbolOpacity(_progress),
                ),
              ),
            ],
          ),
        ),
      );
    }

    const double logoHalf = SplashRevealOverlay.logoSize / 2;
    late final Color logoFill;
    late final Color logoSymbol;
    if (widget.reducedMotion) {
      final (:Color fill, :Color symbol) = _logoColors(
        Curves.easeOut.transform(_progress),
      );
      logoFill = fill;
      logoSymbol = symbol;
    } else {
      final (:Color fill, :Color symbol) = _logoColors(
        Curves.easeInCubic.transform(
          (_progress / SplashRevealOverlay.pulseEndFraction).clamp(0.0, 1.0),
        ),
      );
      logoFill = fill;
      logoSymbol = symbol;
    }

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: coverOpacity, child: _starfield),
            Positioned(
              left: center.dx - logoHalf,
              top: center.dy - logoHalf,
              width: SplashRevealOverlay.logoSize,
              height: SplashRevealOverlay.logoSize,
              child: Opacity(
                opacity: coverOpacity,
                child: Transform.scale(
                  scale: scale,
                  child: InstanceBrandMark(
                    size: SplashRevealOverlay.logoSize,
                    backgroundColor: logoFill,
                    symbolColor: logoSymbol,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildGoldCartoonFrame({
  required double progress,
  required Offset center,
  required bool reducedMotion,
}) {
    const double iconSize = SplashRevealOverlay.logoSize;
    final double vanishProgress = Curves.easeInCubic.transform(
      ((progress - 0.88) / 0.12).clamp(0.0, 1.0),
    );

    // Accessible reduced-motion behavior: no scaling, bouncing, or movement.
    if (reducedMotion) {
      return ExcludeSemantics(
        child: IgnorePointer(
          child: Opacity(
            opacity: 1 - Curves.easeOut.transform(progress),
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

    final double bounceProgress = ((progress - 0.62) / 0.26).clamp(
      0.0,
      1.0,
    );
    final double starScale;
    if (progress < 0.62) {
      starScale = 1;
    } else if (progress < 0.75) {
      starScale = lerpDouble(
        1,
        1.17,
        Curves.easeOutBack.transform(
          ((progress - 0.62) / 0.13).clamp(0.0, 1.0),
        ),
      )!;
    } else if (progress < 0.88) {
      starScale = lerpDouble(
        1.17,
        0.92,
        Curves.bounceOut.transform(
          ((progress - 0.75) / 0.13).clamp(0.0, 1.0),
        ),
      )!;
    } else {
      starScale = 0.92 * (1 - vanishProgress);
    }
    final double hop = -32 *
        math.sin(math.pi * bounceProgress) *
        (1 - bounceProgress);

    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _GoldCartoonBackdropPainter(
                progress: progress,
                logoCenter: center,
              ),
            ),
            Positioned(
              left: center.dx - iconSize / 2,
              top: center.dy - iconSize / 2,
              width: iconSize,
              height: iconSize,
              child: Opacity(
                opacity: 1 - vanishProgress,
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


/// Plays the same official gold-to-white-star exit on the first phone sign-in.
///
/// Unauthenticated users start at /login (not /loading), so the authenticated
/// splash overlay is never shown for them. Painting a gold layer in the first
/// Flutter frame prevents a white flash after Android's native splash.
class StarGoldLaunchTransition extends StatefulWidget {
  const StarGoldLaunchTransition({required this.child, super.key});

  final Widget child;
  static bool _played = false;

  @override
  State<StarGoldLaunchTransition> createState() =>
      _StarGoldLaunchTransitionState();
}

class _StarGoldLaunchTransitionState extends State<StarGoldLaunchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final bool _shouldPlay;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _shouldPlay = !StarGoldLaunchTransition._played;
    StarGoldLaunchTransition._played = true;
    _controller = AnimationController(
      vsync: this,
      duration: SplashRevealOverlay.cartoonDuration,
    );
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _finished = true);
      }
    });
    if (_shouldPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (MediaQuery.disableAnimationsOf(context)) {
          _controller.duration = SplashRevealOverlay.reducedMotionDuration;
        }
        _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldPlay || _finished) {
      return widget.child;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext ctx, Widget? _) {
                return _buildGoldCartoonFrame(
                  progress: _controller.value,
                  center: MediaQuery.sizeOf(ctx).center(Offset.zero),
                  reducedMotion: MediaQuery.disableAnimationsOf(ctx),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldCartoonBackdropPainter extends CustomPainter {
  _GoldCartoonBackdropPainter({
    required this.progress,
    required this.logoCenter,
  });

  final double progress;
  final Offset logoCenter;

  @override
  void paint(Canvas canvas, Size size) {
    final double shrink = Curves.easeInOutCubic.transform(
      ((progress - 0.12) / 0.50).clamp(0.0, 1.0),
    );
    final double vanish = Curves.easeInCubic.transform(
      ((progress - 0.88) / 0.12).clamp(0.0, 1.0),
    );
    final Offset center = Offset.lerp(
      size.center(Offset.zero),
      logoCenter,
      shrink,
    )!;
    const double badgeDiameter = 116;
    final double exitScale = lerpDouble(1, 0.18, vanish)!;
    final double fullDiameter = math.sqrt(size.width * size.width + size.height * size.height) * 1.15;
    final double diameter = lerpDouble(fullDiameter, badgeDiameter, shrink)! * exitScale;
    final double width = diameter;
    final double height = diameter;
    final Rect box = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    final double cornerRadius = diameter / 2;
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

class _SplashRevealPainter extends CustomPainter {
  _SplashRevealPainter({
    required this.symbolColor,
    required this.center,
    required this.scale,
    required this.symbolOpacity,
  });

  final Color symbolColor;
  final Offset center;
  final double scale;
  final double symbolOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (symbolOpacity <= 0) {
      return;
    }

    const double symbolScale =
        SplashRevealOverlay.logoSize / SplashRevealOverlay.symbolViewBox;
    canvas
      ..clipRect(Offset.zero & size)
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(scale)
      ..translate(
        -SplashRevealOverlay.logoSize / 2,
        -SplashRevealOverlay.logoSize / 2,
      )
      ..scale(symbolScale)
      ..drawPath(
        splashRevealSymbolPath(),
        Paint()
          ..color = symbolColor.withValues(alpha: symbolOpacity)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _SplashRevealPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.symbolOpacity != symbolOpacity ||
        oldDelegate.center != center ||
        oldDelegate.symbolColor != symbolColor;
  }
}

const String _kStarSymbolPathData =
    'M121.272 233.143c-13.443 0-24.6738-10.866-23.0194-24.208 1.7884-14.418 5.4904-26.692 11.1064-36.821 8.685-15.39 19.962-26.59 33.828-33.6 14.019-7.009 28.8-10.514 44.343-10.514 15.543 0 29.638 3.505 42.286 10.514 12.8 6.857 27.657 17.372 44.571 31.543 11.429 9.6 20.419 16.457 26.972 20.572 6.704 3.961 14.171 5.942 22.4 5.942 13.257 0 23.695-4.723 31.314-14.171 3.633-4.505 6.348-10.015 8.145-16.53 3.686-13.366 14.025-25.07 27.889-25.07 13.392 0 24.638 10.739 23.095 24.042-1.681 14.49-5.391 26.819-11.129 36.987-8.686 15.39-20.038 26.59-34.057 33.6-14.019 7.009-28.8 10.514-44.343 10.514-15.543 0-29.714-3.276-42.514-9.829-12.8-6.704-27.581-17.447-44.343-32.228-10.972-9.6-19.886-16.381-26.743-20.343-6.857-4.114-14.4-6.172-22.629-6.172-12.343 0-22.552 4.267-30.628 12.8-4.204 4.442-7.252 10.452-9.143 18.031-3.337 13.367-13.623 24.941-27.401 24.941Zm0 138.057c-13.443 0-24.6738-10.866-23.0194-24.207 1.7884-14.419 5.4904-26.693 11.1064-36.822 8.685-15.39 19.962-26.59 33.828-33.6 14.019-7.009 28.8-10.514 44.343-10.514 15.543 0 29.638 3.505 42.286 10.514 12.8 6.858 27.657 17.372 44.571 31.543 11.429 9.6 20.419 16.457 26.972 20.572 6.704 3.962 14.171 5.943 22.4 5.943 13.257 0 23.695-4.724 31.314-14.172 3.633-4.505 6.348-10.015 8.145-16.53 3.686-13.366 14.025-25.07 27.889-25.07 13.392 0 24.638 10.74 23.095 24.042-1.681 14.49-5.391 26.819-11.129 36.987-8.686 15.39-20.038 26.59-34.057 33.6-14.019 7.009-28.8 10.514-44.343 10.514-15.543 0-29.714-3.276-42.514-9.829-12.8-6.704-27.581-17.447-44.343-32.228-10.972-9.6-19.886-16.381-26.743-20.343-6.857-4.114-14.4-6.171-22.629-6.171-12.343 0-22.552 4.266-30.628 12.8-4.204 4.441-7.252 10.451-9.143 18.03-3.337 13.367-13.623 24.941-27.401 24.941Z';

Path? _symbolPath;

Path splashRevealSymbolPath() {
  return _symbolPath ??= _parseSplashRevealSvgPath(_kStarSymbolPathData);
}

Path _parseSplashRevealSvgPath(String source) {
  final Path path = Path();
  final List<double> args = <double>[];
  String command = 'M';
  double cx = 0;
  double cy = 0;
  double startX = 0;
  double startY = 0;

  void apply() {
    switch (command) {
      case 'M':
      case 'm':
        final bool relative = command == 'm';
        for (int i = 0; i + 1 < args.length; i += 2) {
          if (relative) {
            cx += args[i];
            cy += args[i + 1];
          } else {
            cx = args[i];
            cy = args[i + 1];
          }
          if (i == 0) {
            path.moveTo(cx, cy);
            startX = cx;
            startY = cy;
          } else {
            path.lineTo(cx, cy);
          }
        }
      case 'C':
      case 'c':
        final bool relative = command == 'c';
        for (int i = 0; i + 5 < args.length; i += 6) {
          final double x1 = relative ? cx + args[i] : args[i];
          final double y1 = relative ? cy + args[i + 1] : args[i + 1];
          final double x2 = relative ? cx + args[i + 2] : args[i + 2];
          final double y2 = relative ? cy + args[i + 3] : args[i + 3];
          final double x = relative ? cx + args[i + 4] : args[i + 4];
          final double y = relative ? cy + args[i + 5] : args[i + 5];
          path.cubicTo(x1, y1, x2, y2, x, y);
          cx = x;
          cy = y;
        }
      case 'Z':
      case 'z':
        path.close();
        cx = startX;
        cy = startY;
    }
    args.clear();
  }

  final Iterable<RegExpMatch> tokens = RegExp(
    r'([MmZzCc])|([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)',
  ).allMatches(source);
  for (final RegExpMatch token in tokens) {
    final String? nextCommand = token.group(1);
    if (nextCommand != null) {
      apply();
      command = nextCommand;
      continue;
    }
    args.add(double.parse(token.group(2)!));
  }
  apply();
  return path;
}

double splashRevealFadePhaseProgress(double progress) {
  if (progress <= SplashRevealOverlay.pulseEndFraction) {
    return 0;
  }
  return ((progress - SplashRevealOverlay.pulseEndFraction) /
          (1 - SplashRevealOverlay.pulseEndFraction))
      .clamp(0.0, 1.0);
}

double splashRevealLogoScale(
  double progress, {
  required bool reducedMotion,
  required bool useLogoZoomTransition,
}) {
  if (reducedMotion || !useLogoZoomTransition) {
    return 1;
  }
  if (progress <= SplashRevealOverlay.pulseEndFraction) {
    final double t = Curves.easeInCubic.transform(
      progress / SplashRevealOverlay.pulseEndFraction,
    );
    return lerpDouble(1, SplashRevealOverlay.pulseScale, t)!;
  }
  final double expandT = splashRevealFadePhaseProgress(progress);
  return lerpDouble(
    SplashRevealOverlay.pulseScale,
    SplashRevealOverlay.expandScale,
    Curves.easeInCubic.transform(expandT),
  )!;
}

double splashRevealLayerOpacity(
  double progress, {
  required bool reducedMotion,
}) {
  final double p = progress.clamp(0.0, 1.0);
  if (reducedMotion) {
    return 1 - Curves.easeOut.transform(p);
  }
  if (p <= SplashRevealOverlay.pulseEndFraction) {
    return 1;
  }
  final double fadeT = splashRevealFadePhaseProgress(p);
  return 1 - Curves.easeOut.transform(fadeT);
}

double splashRevealSymbolOpacity(double progress) {
  const double fadeWindow = 0.5;
  final double windowT = (splashRevealFadePhaseProgress(progress) / fadeWindow)
      .clamp(0.0, 1.0);
  return 1 - Curves.easeInOut.transform(windowT);
}

double splashRevealShellScale(
  double progress, {
  required bool reducedMotion,
  required bool useLogoZoomTransition,
}) {
  if (reducedMotion || !useLogoZoomTransition) {
    return 1;
  }
  final double t = Curves.easeInOutCubic.transform(progress.clamp(0.0, 1.0));
  return lerpDouble(SplashRevealOverlay.shellStartScale, 1, t)!;
}
