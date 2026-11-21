import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/bootstrap/image_cache_config.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/features/chat/utils/media/media_kit_player_lifecycle.dart';
import 'package:star_app/shared/utils/emoji/emoji_sprite_sheet.dart';
import 'package:star_markdown/star_markdown.dart';

const Duration kBackgroundMemoryTrimDelay = Duration(seconds: 30);

void pauseStarAppMedia() {
  unawaited(MediaKitPlayerLifecycleCoordinator.instance.pauseAll());
}

void trimStarAppMemory(WidgetRef ref, {required bool aggressive}) {
  clearStarImageCache();
  EmojiSpriteSheet.release();
  pauseStarAppMedia();
  try {
    ref.read(chatViewModelProvider.notifier).releaseParkedDisplayWarmers();
  } on Object catch (error, stackTrace) {
    talker.warning(
      '[Memory] Failed to release parked display warmers',
      error,
      stackTrace,
    );
  }
  if (!aggressive) {
    return;
  }
  clearMarkdownParseCaches();
  EmojiAssetCache.clearMemory();
  try {
    ref.read(chatViewModelProvider.notifier).releaseParkedWindows();
  } on Object catch (error, stackTrace) {
    talker.warning(
      '[Memory] Failed to release parked windows',
      error,
      stackTrace,
    );
  }
  unawaited(_shrinkDatabaseMemory(ref));
  talker.debug('[Memory] Trimmed app memory (aggressive: $aggressive)');
}

Future<void> _shrinkDatabaseMemory(WidgetRef ref) async {
  try {
    await ref
        .read(starDatabaseProvider)
        .customStatement('PRAGMA shrink_memory;');
  } on Object catch (error, stackTrace) {
    talker.warning(
      '[Memory] Failed to shrink database memory',
      error,
      stackTrace,
    );
  }
}
