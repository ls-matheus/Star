import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_markdown/star_markdown.dart';

Future<void> showChannelTopicDialog(
  BuildContext context, {
  required String channelName,
  required String topic,
  required String channelId,
}) {
  return StarModal.show<void>(
    context,
    title: channelName,
    centered: true,
    builder: (dialogContext, close) => Padding(
      padding: EdgeInsets.all(dialogContext.layout.s4),
      child: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: MessageMarkdown(
          data: topic,
          channelId: channelId,
          markdownContext: StarMarkdownContext.restrictedChannelTopic,
          baseStyle: dialogContext.textStyles.bodySmall.copyWith(
            color: dialogContext.colors.textSecondary,
          ),
        ),
      ),
    ),
  );
}
