import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:star_app/material_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

const int kStarTypingDotCount = 3;
const double kStarTypingDotSize = 6;
const double kStarTypingDotSpacing = 2;
const List<double> kStarTypingDotDelays = <double>[0, 0.2 / 1.4, 0.4 / 1.4];

const int kStarTypingDotStepsPerCycle = 14;
const Duration kStarTypingDotStepInterval = Duration(milliseconds: 100);

double starTypingDotsWidth({
  double dotSize = kStarTypingDotSize,
  double dotSpacing = kStarTypingDotSpacing,
}) {
  return kStarTypingDotCount * dotSize +
      (kStarTypingDotCount - 1) * dotSpacing;
}

double starTypingDotWave(double progress, double delay) {
  final double phase = (progress - delay) % 1;
  return (math.cos(phase * 2 * math.pi) + 1) / 2;
}

class _StarTypingDotsClock {
  _StarTypingDotsClock._();

  static final ValueNotifier<int> step = ValueNotifier<int>(0);
  static int _subscribers = 0;
  static Timer? _timer;

  static void subscribe(VoidCallback listener) {
    step.addListener(listener);
    _subscribers++;
    _timer ??= Timer.periodic(kStarTypingDotStepInterval, (_) {
      step.value = (step.value + 1) % kStarTypingDotStepsPerCycle;
    });
  }

  static void unsubscribe(VoidCallback listener) {
    step.removeListener(listener);
    _subscribers--;
    if (_subscribers == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

class StarTypingDots extends StatefulWidget {
  const StarTypingDots({
    required this.color,
    this.dotSize = kStarTypingDotSize,
    this.dotSpacing = kStarTypingDotSpacing,
    super.key,
  });

  final Color color;
  final double dotSize;
  final double dotSpacing;

  @override
  State<StarTypingDots> createState() => _StarTypingDotsState();
}

class _StarTypingDotsState extends State<StarTypingDots>
    with WidgetsBindingObserver {
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  ValueListenable<TickerModeData>? _tickerMode;
  bool _isVisible = true;
  bool _animationsEnabled = true;
  bool _subscribed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ValueListenable<TickerModeData> tickerMode =
        TickerMode.getValuesNotifier(context);
    if (!identical(tickerMode, _tickerMode)) {
      _tickerMode?.removeListener(_syncClock);
      _tickerMode = tickerMode..addListener(_syncClock);
    }
    _animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    _syncClock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerMode?.removeListener(_syncClock);
    if (_subscribed) {
      _subscribed = false;
      _StarTypingDotsClock.unsubscribe(_onStep);
    }
    _progress.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _syncClock();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final bool visible = info.visibleFraction > 0;
    if (_isVisible == visible) {
      return;
    }
    _isVisible = visible;
    _syncClock();
  }

  void _syncClock() {
    if (!mounted) {
      return;
    }
    final AppLifecycleState? lifecycleState =
        SchedulerBinding.instance.lifecycleState;
    final bool isForeground =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
    final bool shouldAnimate =
        _isVisible &&
        isForeground &&
        _animationsEnabled &&
        (_tickerMode?.value.enabled ?? true);
    if (shouldAnimate == _subscribed) {
      return;
    }
    _subscribed = shouldAnimate;
    if (shouldAnimate) {
      _StarTypingDotsClock.subscribe(_onStep);
      _onStep();
    } else {
      _StarTypingDotsClock.unsubscribe(_onStep);
    }
  }

  void _onStep() {
    _progress.value =
        _StarTypingDotsClock.step.value / kStarTypingDotStepsPerCycle;
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ObjectKey(this),
      onVisibilityChanged: _onVisibilityChanged,
      child: SizedBox(
        width: starTypingDotsWidth(
          dotSize: widget.dotSize,
          dotSpacing: widget.dotSpacing,
        ),
        height: widget.dotSize,
        child: CustomPaint(
          painter: StarTypingDotsPainter(
            progress: _progress,
            color: widget.color,
            dotSize: widget.dotSize,
            dotSpacing: widget.dotSpacing,
          ),
        ),
      ),
    );
  }
}

class StarTypingDotsPainter extends CustomPainter {
  StarTypingDotsPainter({
    required this.progress,
    required this.color,
    required this.dotSize,
    required this.dotSpacing,
  }) : super(repaint: progress);

  final ValueListenable<double> progress;
  final Color color;
  final double dotSize;
  final double dotSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    final double totalWidth = starTypingDotsWidth(
      dotSize: dotSize,
      dotSpacing: dotSpacing,
    );
    double x = (size.width - totalWidth) / 2;
    final double y = size.height / 2;
    for (int index = 0; index < kStarTypingDotCount; index++) {
      final double wave = starTypingDotWave(
        progress.value,
        kStarTypingDotDelays[index],
      );
      final double opacity = 0.3 + 0.7 * wave;
      final double scale = 0.8 + 0.2 * wave;
      final double radius = dotSize * scale / 2;
      final Paint paint = Paint()
        ..color = color.withValues(alpha: opacity * color.a);
      canvas.drawCircle(Offset(x + dotSize / 2, y), radius, paint);
      x += dotSize + dotSpacing;
    }
  }

  @override
  bool shouldRepaint(covariant StarTypingDotsPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.dotSize != dotSize ||
        oldDelegate.dotSpacing != dotSpacing;
  }
}
