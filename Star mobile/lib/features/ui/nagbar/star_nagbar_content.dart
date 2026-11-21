import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class StarNagbarContent extends StatelessWidget {
  const StarNagbarContent({
    required this.message,
    required this.isMobile,
    this.actions,
    this.onDismiss,
    super.key,
  });

  final String message;
  final bool isMobile;
  final Widget? actions;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final StarLayoutTheme layout = context.layout;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool showMobileDismiss = isMobile && onDismiss != null;
    final Widget? actionRow = (actions != null || showMobileDismiss)
        ? Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: layout.s2,
            runSpacing: isMobile ? layout.s1 : layout.s2,
            children: <Widget>[
              if (showMobileDismiss)
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(
                    foregroundColor: DefaultTextStyle.of(context).style.color,
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.s3,
                      vertical: layout.s2,
                    ),
                    textStyle: context.textStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.chatClientSystemDismiss),
                ),
              ?actions,
            ],
          )
        : null;
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message, textAlign: TextAlign.center),
          if (actionRow != null) ...<Widget>[
            SizedBox(height: layout.s2),
            actionRow,
          ],
        ],
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: layout.s3,
      runSpacing: layout.s2,
      children: <Widget>[
        Text(message, textAlign: TextAlign.center),
        ?actionRow,
      ],
    );
  }
}
