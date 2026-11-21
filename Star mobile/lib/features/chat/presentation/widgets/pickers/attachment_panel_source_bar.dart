import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class AttachmentPanelSourceBar extends StatelessWidget {
  const AttachmentPanelSourceBar({
    required this.onPhotosPressed,
    required this.onFilesPressed,
    super.key,
  });

  final VoidCallback onPhotosPressed;
  final VoidCallback onFilesPressed;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.backgroundFloating,
        borderRadius: layout.radiusFull,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.18),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(layout.s1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            StarButton.ghost(
              icon: PhosphorIconsFill.image,
              label: l10n.chatAttachmentPanelPhotos,
              size: StarButtonSize.small,
              fitContent: true,
              onPressed: onPhotosPressed,
            ),
            StarButton.ghost(
              icon: PhosphorIconsBold.paperclip,
              label: l10n.chatAttachmentPanelFiles,
              size: StarButtonSize.small,
              fitContent: true,
              onPressed: onFilesPressed,
            ),
          ],
        ),
      ),
    );
  }
}
