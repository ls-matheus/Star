import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/spoiler_overlay.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_markdown/star_markdown.dart';

Widget wrapEmbedSpoiler({
  required EmbedType type,
  required bool isSpoiler,
  required bool revealSpoilers,
  required StarSpoilerSyncController? spoilerSyncController,
  required List<String> spoilerSyncKeys,
  required Widget child,
}) {
  final BorderRadius borderRadius =
      type == EmbedType.image ||
          type == EmbedType.gifv ||
          type == EmbedType.video ||
          type == EmbedType.audio
      ? const BorderRadius.all(Radius.circular(4))
      : const BorderRadius.all(Radius.circular(8));

  return SpoilerOverlay(
    isSpoiler: isSpoiler,
    initiallyRevealed: revealSpoilers,
    spoilerSyncController: spoilerSyncController,
    syncKeys: spoilerSyncKeys,
    borderRadius: borderRadius,
    child: child,
  );
}
