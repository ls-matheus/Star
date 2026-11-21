import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/chat/domain/chat_fullscreen_video_launch_context.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/attachment_audio.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/attachment_expiry_footnote.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/attachment_file.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/attachment_image.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/attachment_render_state.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/attachment_video.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/voice_message_player.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_upload_progress.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/spoiler_overlay.dart';
import 'package:star_app/features/chat/utils/attachments/uploading_attachment_utils.dart';
import 'package:star_app/features/chat/utils/attachments/voice_message_attachment.dart';
import 'package:star_app/features/mature_content/presentation/widgets/mature_media_overlay.dart';
import 'package:star_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/user_date_formatting.dart';
import 'package:star_markdown/star_markdown.dart';

class AttachmentRenderer extends ConsumerWidget {
  const AttachmentRenderer({
    required this.attachment,
    required this.inlineAttachmentMedia,
    required this.dimensionSize,
    required this.revealSpoilers,
    this.spoilerSyncController,
    this.spoilerSyncKeys = const [],
    this.imageGallery,
    this.imageGalleryIndex = 0,
    this.messageId,
    this.messageNonce,
    this.messageSendFailed = false,
    this.channelId,
    this.messageFlags = 0,
    this.mediaActionScope,
    super.key,
  });

  final Attachment attachment;
  final bool inlineAttachmentMedia;
  final MediaDimensionSize dimensionSize;
  final bool revealSpoilers;
  final StarSpoilerSyncController? spoilerSyncController;
  final List<String> spoilerSyncKeys;
  final List<Attachment>? imageGallery;
  final int imageGalleryIndex;
  final String? messageId;
  final String? messageNonce;
  final bool messageSendFailed;
  final String? channelId;
  final int messageFlags;
  final MessageMediaActionScope? mediaActionScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AdvancedPreferencesState advanced = ref.watch(
      advancedPreferencesProvider,
    );
    final AttachmentRenderState renderState = buildAttachmentRenderState(
      attachment: attachment,
      inlineAttachmentMedia: inlineAttachmentMedia,
    );
    final Widget content = _buildContent(renderState, advanced: advanced);
    final DateTime? expiresAt = attachment.expiresAt;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String? expiryFootnoteText = expiresAt == null
        ? null
        : l10n.chatAttachmentExpiresOn(
            formatUserMediumDate(expiresAt.toLocal(), l10n.localeName),
          );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SpoilerOverlay(
            isSpoiler: attachment.isSpoiler,
            initiallyRevealed: revealSpoilers,
            spoilerSyncController: spoilerSyncController,
            syncKeys: spoilerSyncKeys,
            child: _wrapMatureMedia(content),
          ),
          if (expiryFootnoteText != null &&
              advanced.showAttachmentExpiryIndicator)
            AttachmentExpiryFootnote(text: expiryFootnoteText),
        ],
      ),
    );
  }

  Widget _wrapMatureMedia(Widget child) {
    if (!attachment.isMatureMedia || channelId == null) {
      return child;
    }
    return MatureMediaOverlay(
      channelId: channelId,
      isMatureMedia: true,
      child: child,
    );
  }

  Widget _buildContent(
    AttachmentRenderState renderState, {
    required AdvancedPreferencesState advanced,
  }) {
    if (isUploadingPlaceholderAttachment(attachment) &&
        messageId != null &&
        messageNonce != null &&
        channelId != null) {
      return MessageUploadProgress(
        attachment: attachment,
        messageId: messageId!,
        messageNonce: messageNonce!,
        failed: messageSendFailed,
      );
    }
    if (renderState.shouldRenderAsFile) {
      return AttachmentFile(attachment: attachment);
    }
    return switch (renderState.type) {
      AttachmentRenderType.image => AttachmentImage(
        attachment: attachment,
        dimensionSize: dimensionSize,
        revealSpoiler: revealSpoilers,
        wrapWithSpoiler: false,
        imageGallery: imageGallery,
        imageGalleryIndex: imageGalleryIndex,
        channelId: channelId,
        messageId: messageId,
        mediaActionScope: mediaActionScope,
        showGifIndicator: advanced.showGifIndicator,
      ),
      AttachmentRenderType.video => AttachmentVideo(
        attachment: attachment,
        dimensionSize: dimensionSize,
        videoActionScope: mediaActionScope,
      ),
      AttachmentRenderType.audio =>
        isVoiceMessageAttachment(
              messageFlags: messageFlags,
              attachment: attachment,
            )
            ? VoiceMessagePlayer(attachment: attachment)
            : AttachmentAudio(attachment: attachment),
      AttachmentRenderType.file => AttachmentFile(attachment: attachment),
    };
  }
}
