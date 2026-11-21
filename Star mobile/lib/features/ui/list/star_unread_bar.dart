import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';

enum StarUnreadBarEdge { start, end, top, bottom }

class StarUnreadBar extends StatelessWidget {
  const StarUnreadBar({
    required this.visible,
    this.edge = StarUnreadBarEdge.start,
    this.thickness = 8,
    this.length = 8,
    this.alignment = 0.5,
    this.bleed = 0,
    this.color,
    this.faded = false,
    this.duration,
    super.key,
  });

  final bool visible;

  final StarUnreadBarEdge edge;

  final double thickness;

  final double length;

  final double alignment;

  final double bleed;

  final Color? color;

  final bool faded;

  final Duration? duration;

  bool get _isHorizontal =>
      edge == StarUnreadBarEdge.top || edge == StarUnreadBarEdge.bottom;

  AlignmentGeometry get _alignment {
    final along = alignment * 2 - 1;
    return switch (edge) {
      StarUnreadBarEdge.start => AlignmentDirectional(-1, along),
      StarUnreadBarEdge.end => AlignmentDirectional(1, along),
      StarUnreadBarEdge.top => Alignment(along, -1),
      StarUnreadBarEdge.bottom => Alignment(along, 1),
    };
  }

  Offset _bleedOffset(TextDirection direction) {
    final double startBleed = direction == TextDirection.rtl ? bleed : -bleed;
    return switch (edge) {
      StarUnreadBarEdge.start => Offset(startBleed, 0),
      StarUnreadBarEdge.end => Offset(-startBleed, 0),
      StarUnreadBarEdge.top => Offset(0, -bleed),
      StarUnreadBarEdge.bottom => Offset(0, bleed),
    };
  }

  BorderRadiusGeometry _borderRadius() {
    final r = Radius.circular(thickness);
    return switch (edge) {
      StarUnreadBarEdge.start => BorderRadiusDirectional.only(
        topEnd: r,
        bottomEnd: r,
      ),
      StarUnreadBarEdge.end => BorderRadiusDirectional.only(
        topStart: r,
        bottomStart: r,
      ),
      StarUnreadBarEdge.top => BorderRadius.only(
        bottomLeft: r,
        bottomRight: r,
      ),
      StarUnreadBarEdge.bottom => BorderRadius.only(topLeft: r, topRight: r),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = (color ?? context.colors.textPrimary).withValues(
      alpha: faded ? 0.5 : 1.0,
    );

    final targetLength = visible ? length : 0.0;
    final width = _isHorizontal ? targetLength : thickness;
    final height = _isHorizontal ? thickness : targetLength;

    return ExcludeSemantics(
      child: Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: _alignment,
            child: Transform.translate(
              offset: _bleedOffset(Directionality.of(context)),
              child: AnimatedContainer(
                duration: duration ?? context.motion.panel,
                curve: context.motion.curve,
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: resolvedColor,
                  borderRadius: _borderRadius(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@StarWidgetPreview(name: 'Left edge, centered', group: 'StarUnreadBar')
Widget starUnreadBarLeftPreview() {
  return const SizedBox(
    width: 240,
    height: 64,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ColoredBox(color: Color(0xFF1E1E22)),
        StarUnreadBar(visible: true, bleed: 4),
      ],
    ),
  );
}

@StarWidgetPreview(
  name: 'Left edge, bottom aligned, bleed',
  group: 'StarUnreadBar',
)
Widget starUnreadBarLeftBottomPreview() {
  return const SizedBox(
    width: 240,
    height: 64,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ColoredBox(color: Color(0xFF1E1E22)),
        StarUnreadBar(visible: true, alignment: 1, bleed: 4),
      ],
    ),
  );
}

@StarWidgetPreview(name: 'Faded', group: 'StarUnreadBar')
Widget starUnreadBarFadedPreview() {
  return const SizedBox(
    width: 240,
    height: 64,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ColoredBox(color: Color(0xFF1E1E22)),
        StarUnreadBar(visible: true, faded: true, bleed: 4),
      ],
    ),
  );
}
