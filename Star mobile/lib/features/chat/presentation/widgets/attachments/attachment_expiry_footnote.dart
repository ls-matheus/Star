import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/material_ui.dart';

const String attachmentExpiryHelpUrl =
    'https://star.invalid/help/attachment-expiry';

class AttachmentExpiryFootnote extends StatelessWidget {
  const AttachmentExpiryFootnote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: StarTextLink(
        text: text,
        url: attachmentExpiryHelpUrl,
        color: context.colors.textChatMuted,
        style: context.textStyles.smallText.copyWith(fontSize: 10, height: 1.2),
      ),
    );
  }
}
