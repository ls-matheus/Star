import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/material_ui.dart';

class DesktopSidebarHeaderSurface extends StatelessWidget {
  const DesktopSidebarHeaderSurface({
    required this.height,
    required this.child,
    this.active = false,
    this.padding,
    super.key,
  });

  final double height;
  final bool active;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color background = colors.channelSidebarBackground;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active
              ? starDesktopHoverOver(context, background)
              : background,
          border: Border(
            bottom: BorderSide(color: colors.userAreaDividerColor),
          ),
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}
