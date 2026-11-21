import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

enum HideMutedChannelsChoice { applyAll, newOnly }

Future<HideMutedChannelsChoice?> showHideMutedChannelsConfirmSheet(
  BuildContext context, {
  required bool value,
}) {
  final l10n = StarLocalizations.of(context);
  final title = value
      ? l10n.messagesMediaDefaultHideMutedChannelsEnableTitle
      : l10n.messagesMediaDefaultHideMutedChannelsDisableTitle;
  final description = value
      ? l10n.messagesMediaDefaultHideMutedChannelsEnableDescription
      : l10n.messagesMediaDefaultHideMutedChannelsDisableDescription;
  final primaryLabel = value
      ? l10n.messagesMediaDefaultHideMutedChannelsApplyAllAction
      : l10n.messagesMediaDefaultHideMutedChannelsShowAllAction;

  return StarBottomSheet.show<HideMutedChannelsChoice>(
    context,
    useRootNavigator: true,
    title: title,
    builder: (sheetContext, close) {
      final layout = sheetContext.layout;
      final colors = sheetContext.colors;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: layout.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              description,
              style: sheetContext.textStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: layout.s5),
            StarButton.primary(
              onPressed: () => Navigator.of(
                sheetContext,
              ).pop(HideMutedChannelsChoice.applyAll),
              label: primaryLabel,
            ),
            SizedBox(height: layout.s2),
            StarButton.secondary(
              onPressed: () => Navigator.of(
                sheetContext,
              ).pop(HideMutedChannelsChoice.newOnly),
              label: l10n.messagesMediaDefaultHideMutedChannelsNewOnlyAction,
            ),
          ],
        ),
      );
    },
  );
}
