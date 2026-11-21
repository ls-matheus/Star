import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/domain/chat_fullscreen_video_launch_context.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/media/chat_inline_video_player.dart';
import 'package:star_app/features/chat/presentation/widgets/media/media_alt_text.dart';
import 'package:star_app/features/chat/utils/media/media_dimension_utils.dart';
import 'package:star_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:star_app/material_ui.dart';

typedef AttachmentVideoControlsBuilder = ChatVideoControlsBuilder;

class AttachmentVideo extends StatelessWidget {
  const AttachmentVideo({
    required this.attachment,
    this.dimensionSize = MediaDimensionSize.small,
    this.controlsBuilder,
    this.videoActionScope,
    super.key,
  });

  final Attachment attachment;
  final MediaDimensionSize dimensionSize;
  final AttachmentVideoControlsBuilder? controlsBuilder;
  final MessageMediaActionScope? videoActionScope;

  @override
  Widget build(BuildContext context) {
    final StarMediaDimensions dimensions = mediaDimensionsForSize(
      dimensionSize,
    );
    final ChatFullscreenVideoLaunchContext launchContext =
        ChatFullscreenVideoLaunchContext.fromAttachment(
          attachment: attachment,
          layoutDimensions: dimensions,
          actionScope: videoActionScope,
        );
    final Size? displaySize = constrainMediaSize(
      dimensions: dimensions,
      width: attachment.width,
      height: attachment.height,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 3),
      child: MediaAltText(
        altText: attachment.description,
        captionWidth: displaySize?.width ?? dimensions.maxWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dimensions.maxWidth,
            maxHeight: dimensions.maxHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.backgroundSecondaryAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ChatInlineVideoPlayer(
                source: launchContext.source,
                launchContext: launchContext,
                dimensionSize: dimensionSize,
                controlsBuilder: controlsBuilder,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
