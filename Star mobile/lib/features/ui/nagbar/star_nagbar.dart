import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/focus_ring/star_focus_ring.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class StarNagbar extends StatelessWidget {
  const StarNagbar({
    required this.backgroundColor,
    required this.textColor,
    required this.isMobile,
    required this.child,
    this.onDismiss,
    this.dismissible = false,
    super.key,
  });

  final Color backgroundColor;
  final Color textColor;
  final bool isMobile;
  final Widget child;
  final VoidCallback? onDismiss;
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final StarLayoutTheme layout = context.layout;
    final bool showDismissButton =
        dismissible && onDismiss != null && !isMobile;
    final double minHeight = isMobile ? 48 : 36;
    final double fontSize = isMobile ? 12 : 14;
    return Semantics(
      container: true,
      liveRegion: true,
      child: ColoredBox(
        color: backgroundColor,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: layout.s2,
            vertical: isMobile ? layout.s2 : layout.s1,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: DefaultTextStyle(
                  style: context.textStyles.bodySmall.copyWith(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: isMobile ? FontWeight.w500 : FontWeight.w600,
                  ),
                  child: IconTheme(
                    data: IconThemeData(color: textColor, size: 16),
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: showDismissButton ? 32 : 0,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
              if (showDismissButton)
                PositionedDirectional(
                  end: 0,
                  child: StarFocusRing(
                    focused: false,
                    child: Semantics(
                      button: true,
                      label: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onTap: onDismiss,
                      excludeSemantics: true,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onDismiss,
                          child: Padding(
                            padding: EdgeInsets.all(layout.s1),
                            child: Icon(
                              PhosphorIconsBold.x,
                              color: textColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
