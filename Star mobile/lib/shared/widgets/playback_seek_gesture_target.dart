import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/gestures/nested_horizontal_scrollable.dart';

class PlaybackSeekGestureTarget extends StatelessWidget {
  const PlaybackSeekGestureTarget({
    required this.child,
    required this.onSeekFraction,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final ValueChanged<double> onSeekFraction;
  final bool enabled;

  void _seekFromLocalDx(double localDx, double width) {
    if (!enabled || width <= 0) {
      return;
    }
    onSeekFraction(localDx / width);
  }

  @override
  Widget build(BuildContext context) {
    final double touchTargetHeight = context.layout.touchTargetMin;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final Widget timeline = Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: child),
        );
        return SizedBox(
          key: enabled ? kPlaybackSeekShellGestureBlockKey : null,
          height: touchTargetHeight,
          child: enabled
              ? StarGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (TapDownDetails details) {
                    _seekFromLocalDx(details.localPosition.dx, width);
                  },
                  onHorizontalDragStart: (DragStartDetails details) {
                    _seekFromLocalDx(details.localPosition.dx, width);
                  },
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    _seekFromLocalDx(details.localPosition.dx, width);
                  },
                  child: timeline,
                )
              : timeline,
        );
      },
    );
  }
}
