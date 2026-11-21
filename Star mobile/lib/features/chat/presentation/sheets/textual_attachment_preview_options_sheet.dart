import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

enum TextualAttachmentPreviewOption { download, wrapText }

Future<TextualAttachmentPreviewOption?>
showTextualAttachmentPreviewOptionsSheet({
  required BuildContext context,
  required bool wrapText,
  required bool showWrapText,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  return StarBottomSheet.show<TextualAttachmentPreviewOption>(
    context,
    title: l10n.chatTextualPreviewMoreOptions,
    variant: StarBottomSheetVariant.menu,
    builder: (BuildContext sheetContext, VoidCallback close) {
      return StarBottomSheetContent(
        scrollable: false,
        child: StarMenuGroup(
          children: [
            StarBottomSheetMenuItem(
              label: l10n.chatAttachmentDownload,
              icon: PhosphorIconsBold.downloadSimple,
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(TextualAttachmentPreviewOption.download),
            ),
            if (showWrapText)
              StarBottomSheetMenuItem(
                label: l10n.chatTextualPreviewWrapText,
                icon: PhosphorIconsBold.textAa,
                isSelected: wrapText,
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(TextualAttachmentPreviewOption.wrapText),
              ),
          ],
        ),
      );
    },
  );
}
