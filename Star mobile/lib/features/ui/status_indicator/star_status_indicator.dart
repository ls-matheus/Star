import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';

const double _kIdleBiteCenter = 0.25;
const double _kIdleBiteRadius = 0.375;
const double _kDndBarWidth = 0.73;
const double _kDndBarHeight = 0.23;
const double _kOfflineHoleDiameter = 0.47;

Color resolveStatusColor(BuildContext context, String status) {
  final colors = context.colors;
  return switch (status) {
    'online' => colors.statusOnline,
    'idle' => colors.statusIdle,
    'dnd' => colors.statusDnd,
    _ => colors.statusOffline,
  };
}

class StarStatusIndicator extends StatelessWidget {
  const StarStatusIndicator({
    required this.status,
    this.size = 15,
    this.color,
    super.key,
  });

  final String status;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: StarStatusPainter(
          status: status,
          color: color ?? resolveStatusColor(context, status),
        ),
      ),
    );
  }
}

class StarStatusPainter extends CustomPainter {
  const StarStatusPainter({required this.status, required this.color});

  final String status;
  final Color color;

  static Path glyphPath(String status, Rect bounds) {
    final double side = bounds.shortestSide;
    final Rect square = Rect.fromCenter(
      center: bounds.center,
      width: side,
      height: side,
    );
    final Path shape = Path()
      ..addRRect(RRect.fromRectAndRadius(bounds, Radius.circular(side / 2)));
    final Path? hole = switch (status) {
      'idle' =>
        Path()..addOval(
          Rect.fromCircle(
            center: square.topLeft + Offset(side, side) * _kIdleBiteCenter,
            radius: side * _kIdleBiteRadius,
          ),
        ),
      'dnd' =>
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: square.center,
              width: side * _kDndBarWidth,
              height: side * _kDndBarHeight,
            ),
            Radius.circular(side * _kDndBarHeight / 2),
          ),
        ),
      'offline' || 'invisible' =>
        Path()..addOval(
          Rect.fromCircle(
            center: square.center,
            radius: side * _kOfflineHoleDiameter / 2,
          ),
        ),
      _ => null,
    };
    if (hole == null) {
      return shape;
    }
    return Path.combine(PathOperation.difference, shape, hole);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    canvas.drawPath(
      glyphPath(status, Offset.zero & size),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(StarStatusPainter oldDelegate) =>
      status != oldDelegate.status || color != oldDelegate.color;
}

@StarWidgetPreview(name: 'Online', group: 'StarStatusIndicator')
Widget starStatusOnlinePreview() {
  return const StarStatusIndicator(status: 'online');
}

@StarWidgetPreview(name: 'Idle', group: 'StarStatusIndicator')
Widget starStatusIdlePreview() {
  return const StarStatusIndicator(status: 'idle');
}

@StarWidgetPreview(name: 'DND', group: 'StarStatusIndicator')
Widget starStatusDndPreview() {
  return const StarStatusIndicator(status: 'dnd');
}

@StarWidgetPreview(name: 'Offline', group: 'StarStatusIndicator')
Widget starStatusOfflinePreview() {
  return const StarStatusIndicator(status: 'offline');
}
