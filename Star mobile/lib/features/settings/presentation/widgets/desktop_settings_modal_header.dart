import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class DesktopSettingsModalHeader extends StatelessWidget {
  const DesktopSettingsModalHeader({
    required this.title,
    required this.onClose,
    this.titleTrailing,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  final String title;
  final VoidCallback onClose;
  final Widget? titleTrailing;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: colors.backgroundModifierAccent),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.heading.copyWith(
                        fontSize: 18,
                        height: 24 / 18,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor ?? colors.textPrimary,
                      ),
                    ),
                  ),
                  if (titleTrailing != null) ...<Widget>[
                    const SizedBox(width: 8),
                    titleTrailing!,
                  ],
                ],
              ),
            ),
          ),
          StarButton.desktop(
            icon: PhosphorIconsBold.x,
            semanticLabel: StarLocalizations.of(context).uiClose,
            onPressed: onClose,
            extent: 34,
            borderRadius: 8,
            color: foregroundColor ?? colors.textTertiary,
            hoverColor: foregroundColor ?? colors.textPrimary,
            hoverBackground: colors.surfaceInteractiveHoverBg,
            duration: const Duration(milliseconds: 120),
          ),
        ],
      ),
    );
  }
}
