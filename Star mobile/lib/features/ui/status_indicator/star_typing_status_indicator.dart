import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/spinner/star_typing_dots.dart';
import 'package:star_app/features/ui/status_indicator/star_status_indicator.dart';
import 'package:star_app/material_ui.dart';

const double _kDotSizeRatio = 0.25;
const double _kDotGapRatio = 0.12;

class StarTypingStatusIndicator extends StatelessWidget {
  const StarTypingStatusIndicator({
    required this.status,
    required this.width,
    required this.height,
    this.color,
    super.key,
  });

  final String status;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = color ?? resolveStatusColor(context, status);
    final double dotSize = height * _kDotSizeRatio;
    final double dotSpacing = height * _kDotGapRatio;

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Center(
            child: StarTypingDots(
              color: Colors.white,
              dotSize: dotSize,
              dotSpacing: dotSpacing,
            ),
          ),
        ),
      ),
    );
  }
}

@StarWidgetPreview(
  name: 'Online typing',
  group: 'StarTypingStatusIndicator',
)
Widget starTypingStatusOnlinePreview() {
  return const StarTypingStatusIndicator(
    status: 'online',
    width: 22,
    height: 12,
  );
}

@StarWidgetPreview(name: 'Idle typing', group: 'StarTypingStatusIndicator')
Widget starTypingStatusIdlePreview() {
  return const StarTypingStatusIndicator(
    status: 'idle',
    width: 22,
    height: 12,
  );
}
