import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoActivityIndicator;
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/animation/animation_controller_visibility_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

enum StarLoadingSpinnerSize {
  small(20),
  medium(30),
  large(35);

  const StarLoadingSpinnerSize(this.diameter);

  final double diameter;
}

class StarLoadingSpinner extends StatelessWidget {
  const StarLoadingSpinner({
    super.key,
    this.color,
    this.size = StarLoadingSpinnerSize.large,
    this.revealProgress,
  });

  final Color? color;
  final StarLoadingSpinnerSize size;
  final double? revealProgress;

  @override
  Widget build(BuildContext context) {
    final Color spokeColor = color ?? context.colors.textTertiary;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool animating = !MediaQuery.disableAnimationsOf(context);
    final double? progress = revealProgress;

    if (progress == null && usesDesktopPointerUi(context)) {
      return Semantics(
        label: l10n.uiLoading,
        child: ExcludeSemantics(
          child: StarPulsingEllipsis(
            color: color ?? context.colors.textSecondary,
            dotSize: switch (size) {
              StarLoadingSpinnerSize.small => 6,
              StarLoadingSpinnerSize.medium => 8,
              StarLoadingSpinnerSize.large => 10,
            },
          ),
        ),
      );
    }

    return Semantics(
      label: l10n.uiLoading,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: progress != null
              ? CupertinoActivityIndicator.partiallyRevealed(
                  color: spokeColor,
                  radius: size.diameter / 2,
                  progress: progress,
                )
              : CupertinoActivityIndicator(
                  color: spokeColor,
                  radius: size.diameter / 2,
                  animating: animating,
                ),
        ),
      ),
    );
  }
}

const int _kEllipsisPeriodMs = 1400;
const List<int> _kEllipsisDelaysMs = <int>[0, 200, 400];
const double _kEllipsisGap = 2;
const double _kEllipsisRadius = 4;

class StarPulsingEllipsis extends StatefulWidget {
  const StarPulsingEllipsis({
    required this.color,
    required this.dotSize,
    super.key,
  });

  final Color color;
  final double dotSize;

  @override
  State<StarPulsingEllipsis> createState() => _StarPulsingEllipsisState();
}

class _StarPulsingEllipsisState extends State<StarPulsingEllipsis>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _kEllipsisPeriodMs),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool animating = !MediaQuery.disableAnimationsOf(context);
    _controller.syncWithVisibility(
      isVisible: true,
      animationsEnabled: animating,
    );
    return CustomPaint(
      size: Size(widget.dotSize * 3 + _kEllipsisGap * 2, widget.dotSize),
      painter: _PulsingEllipsisPainter(
        animation: _controller,
        color: widget.color,
        dotSize: widget.dotSize,
        animating: animating,
      ),
    );
  }
}

class _PulsingEllipsisPainter extends CustomPainter {
  _PulsingEllipsisPainter({
    required this.animation,
    required this.color,
    required this.dotSize,
    required this.animating,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final double dotSize;
  final bool animating;

  double _phase(int delayMs) {
    final double elapsed = animation.value * _kEllipsisPeriodMs - delayMs;
    final double t = (elapsed % _kEllipsisPeriodMs) / _kEllipsisPeriodMs;
    final double half = t <= 0.5 ? t / 0.5 : (1 - t) / 0.5;
    return Curves.easeInOut.transform(half);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (var i = 0; i < _kEllipsisDelaysMs.length; i++) {
      final double p = animating ? _phase(_kEllipsisDelaysMs[i]) : 0;
      final double opacity = animating ? 1 - 0.7 * p : 0.6;
      final double scale = 1 - 0.2 * p;
      final double side = dotSize * scale;
      final Offset center = Offset(
        i * (dotSize + _kEllipsisGap) + dotSize / 2,
        dotSize / 2,
      );
      paint.color = color.withValues(alpha: color.a * opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: side, height: side),
          Radius.circular(_kEllipsisRadius * scale),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PulsingEllipsisPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.color != color ||
      oldDelegate.dotSize != dotSize ||
      oldDelegate.animating != animating;
}

@StarWidgetPreview(name: 'Default', group: 'StarLoadingSpinner')
Widget starLoadingSpinnerPreview() {
  return const StarLoadingSpinner();
}

@StarWidgetPreview(name: 'Small', group: 'StarLoadingSpinner')
Widget starLoadingSpinnerSmallPreview() {
  return const StarLoadingSpinner(size: StarLoadingSpinnerSize.small);
}
