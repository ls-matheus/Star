import 'package:star_app/core/build/push_provider_guard.dart';
import 'package:star_app/core/push/web_push/web_push_relay.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/features/ui/text_link/star_text_link.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

Future<bool?> showPushRelayConsentSheet(BuildContext context) {
  final l10n = StarLocalizations.of(context);
  final colors = context.colors;
  final textStyles = context.textStyles;

  Widget buildContent(BuildContext overlayContext) {
    return _PushRelayConsentSheetContent(
      onAgree: () =>
          Navigator.of(overlayContext, rootNavigator: true).pop(true),
      onDecline: () =>
          Navigator.of(overlayContext, rootNavigator: true).pop(false),
    );
  }

  if (isMobileLayout(context)) {
    return StarBottomSheet.show<bool>(
      context,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      title: l10n.pushRelayConsentTitle,
      subtitle: Text(
        l10n.pushRelayConsentDescription(
          pushRelayProviderName(isApple: PushProviderGuard.isApple),
        ),
        style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
      ),
      builder: (sheetContext, close) => buildContent(sheetContext),
    );
  }

  return StarModal.show<bool>(
    context,
    useRootNavigator: true,
    centered: true,
    title: l10n.pushRelayConsentTitle,
    description: l10n.pushRelayConsentDescription(
      pushRelayProviderName(isApple: PushProviderGuard.isApple),
    ),
    trailing: Opacity(
      opacity: 0.7,
      child: StarButton.ghost(
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
        icon: PhosphorIconsBold.x,
        isSquare: true,
        semanticLabel: l10n.uiClose,
      ),
    ),
    builder: (dialogContext, close) => buildContent(dialogContext),
  );
}

class _PushRelayConsentSheetContent extends StatelessWidget {
  const _PushRelayConsentSheetContent({
    required this.onAgree,
    required this.onDecline,
  });

  final VoidCallback onAgree;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);
    final TextStyle bodyStyle = textStyles.bodySmall.copyWith(
      color: colors.textSecondary,
    );

    return PopScope(
      canPop: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  TextSpan(text: l10n.pushRelayConsentNoticePrefix),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: MediaQuery.withNoTextScaling(
                      child: StarTextLink(
                        text: l10n.pushRelayConsentNoticeLink,
                        url: kPushRelayNoticeUrl,
                        style: bodyStyle,
                      ),
                    ),
                  ),
                  TextSpan(text: l10n.pushRelayConsentNoticeSuffix),
                ],
              ),
            ),
            SizedBox(height: layout.s4),
            StarButton.primary(
              onPressed: onAgree,
              label: l10n.pushRelayConsentAgree,
            ),
            SizedBox(height: layout.s2),
            StarButton.secondary(
              onPressed: onDecline,
              label: l10n.pushRelayConsentDecline,
            ),
          ],
        ),
      ),
    );
  }
}
