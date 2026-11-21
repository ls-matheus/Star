import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_item.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_preview_card.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/system_message.dart';
import 'package:star_app/material_ui.dart';

class MessageConfirmPreview extends ConsumerWidget {
  const MessageConfirmPreview({required this.message, this.guildId, super.key});

  final Message message;
  final String? guildId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MessagePreviewCard(
      child: message.isSystemMessage
          ? SystemMessage(message: message, guildId: guildId)
          : MessageItem(
              message: message,
              inboxPreviewMode: true,
              hideMentionHighlight: true,
              previewRoleGuildId: guildId,
              currentUserId: ref.watch(currentUserIdProvider),
            ),
    );
  }
}
