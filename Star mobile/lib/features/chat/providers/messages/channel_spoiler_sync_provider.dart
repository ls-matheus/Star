import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:star_markdown/star_markdown.dart';

final ProviderFamily<StarSpoilerSyncController, String>
channelSpoilerSyncProvider = Provider.autoDispose
    .family<StarSpoilerSyncController, String>((Ref ref, String _) {
      final StarSpoilerSyncController controller =
          StarSpoilerSyncController();
      ref.onDispose(controller.dispose);
      return controller;
    });
