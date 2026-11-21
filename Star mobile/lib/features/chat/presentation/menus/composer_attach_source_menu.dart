import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

enum ComposerAttachSource { gallery, files }

Future<ComposerAttachSource?> showComposerAttachSourceMenu(
  BuildContext context,
) async {
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  final Offset position = box != null && box.hasSize
      ? box.localToGlobal(Offset(0, box.size.height))
      : Offset.zero;
  ComposerAttachSource? selected;
  await StarActionMenu.show(
    context,
    position: position,
    builder: (BuildContext menuContext, VoidCallback close) {
      final StarLocalizations l10n = StarLocalizations.of(menuContext);
      return <Widget>[
        StarMenuItem(
          label: l10n.chatAttachmentSourceGallery,
          icon: PhosphorIconsFill.image,
          onPressed: () {
            selected = ComposerAttachSource.gallery;
            close();
          },
        ),
        StarMenuItem(
          label: l10n.chatAttachmentSourceBrowse,
          icon: PhosphorIconsBold.paperclip,
          onPressed: () {
            selected = ComposerAttachSource.files;
            close();
          },
        ),
      ];
    },
  );
  return selected;
}
