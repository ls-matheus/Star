import 'package:star_app/features/settings/utils/expressions/expression_file_picker.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

enum ExpressionUploadSource { gallery, files }

Future<List<ExpressionPickResult>> pickGuildExpressionEmojis(
  BuildContext context,
) async {
  if (!isMobileLayout(context)) {
    return await ExpressionFilePicker.pickEmojis();
  }
  final ExpressionUploadSource? source = await _showUploadSourceSheet(context);
  if (source == null) {
    return const <ExpressionPickResult>[];
  }
  return await switch (source) {
    ExpressionUploadSource.gallery =>
      ExpressionFilePicker.pickEmojisFromGallery(),
    ExpressionUploadSource.files => ExpressionFilePicker.pickEmojisFromFiles(),
  };
}

Future<List<ExpressionPickResult>> pickGuildExpressionSticker(
  BuildContext context,
) async {
  if (!isMobileLayout(context)) {
    return await ExpressionFilePicker.pickSticker();
  }
  final ExpressionUploadSource? source = await _showUploadSourceSheet(context);
  if (source == null) {
    return const <ExpressionPickResult>[];
  }
  return await switch (source) {
    ExpressionUploadSource.gallery =>
      ExpressionFilePicker.pickStickerFromGallery(),
    ExpressionUploadSource.files => ExpressionFilePicker.pickStickerFromFiles(),
  };
}

Future<ExpressionUploadSource?> _showUploadSourceSheet(BuildContext context) {
  return StarBottomSheet.show<ExpressionUploadSource>(
    context,
    variant: StarBottomSheetVariant.menu,
    builder: (BuildContext sheetContext, _) {
      final StarLocalizations l10n = StarLocalizations.of(sheetContext);
      return StarBottomSheetContent(
        scrollable: false,
        child: StarBottomSheetGroupColumn(
          children: <Widget>[
            StarMenuGroup(
              children: <Widget>[
                StarBottomSheetMenuItem(
                  icon: PhosphorIconsFill.image,
                  label: l10n.chatAttachmentSourceGallery,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(ExpressionUploadSource.gallery),
                ),
                StarBottomSheetMenuItem(
                  icon: PhosphorIconsFill.folder,
                  label: l10n.chatAttachmentSourceBrowse,
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(ExpressionUploadSource.files),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
