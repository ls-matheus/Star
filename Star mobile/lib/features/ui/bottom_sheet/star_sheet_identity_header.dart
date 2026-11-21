import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/button/star_button_variant.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class StarSheetIdentityHeader extends StatelessWidget {
  const StarSheetIdentityHeader({
    required this.leading,
    required this.title,
    this.subtitle,
    this.titlePrefix,
    this.titleAdornments,
    this.onClose,
    this.closeOnLeading = false,
    this.hideLeading = false,
    this.body,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? titlePrefix;
  final List<Widget>? titleAdornments;
  final VoidCallback? onClose;
  final bool closeOnLeading;
  final bool hideLeading;

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final adornments = titleAdornments ?? const <Widget>[];
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return StarBottomSheetDragArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.layout.s4,
          context.layout.s2,
          context.layout.s4,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: onClose != null && closeOnLeading ? 40 : 0,
                    end: onClose != null && !closeOnLeading ? 40 : 0,
                  ),
                  child: Row(
                    children: [
                      if (!hideLeading) ...[leading, const SizedBox(width: 12)],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                if (titlePrefix != null) ...[
                                  titlePrefix!,
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    title,
                                    style: context.textStyles.channelName
                                        .copyWith(fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                for (final a in adornments) ...[
                                  const SizedBox(width: 6),
                                  a,
                                ],
                              ],
                            ),
                            if (hasSubtitle) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: context.textStyles.bodySmall.copyWith(
                                  color: context.colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  PositionedDirectional(
                    start: closeOnLeading ? 0 : null,
                    end: closeOnLeading ? null : 0,
                    top: 0,
                    child: closeOnLeading
                        ? StarSheetCloseButton(
                            onTap: onClose!,
                            icon: PhosphorIconsBold.arrowLeft,
                            semanticLabel: StarLocalizations.of(context).back,
                          )
                        : StarSheetCloseButton(onTap: onClose!),
                  ),
              ],
            ),
            if (body != null) ...[SizedBox(height: context.layout.s3), body!],
          ],
        ),
      ),
    );
  }
}

class StarSheetCloseButton extends StatelessWidget {
  const StarSheetCloseButton({
    required this.onTap,
    this.icon = PhosphorIconsBold.x,
    this.semanticLabel,
    super.key,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarButton.circle(
      icon: icon,
      variant: StarButtonVariant.ghost,
      size: StarButtonSize.small,
      iconSize: 18,
      onPressed: onTap,
      semanticLabel: semanticLabel ?? l10n.uiClose,
    );
  }
}
