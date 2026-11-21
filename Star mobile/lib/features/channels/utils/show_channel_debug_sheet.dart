import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/shared/utils/sdk_converters.dart';
import 'package:star_app/shared/widgets/debug_bottom_sheet.dart';

Future<void> showChannelDebugSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String channelId,
  required String title,
}) async {
  Map<String, Object?>? data;
  final localChannel = await ref
      .read(starDatabaseProvider)
      .channelDao
      .getChannelById(channelId);
  if (localChannel != null) {
    data = channelResponseFromRow(localChannel).toJson();
  } else {
    try {
      final channel = await ref
          .read(starClientProvider)
          .channels
          .getChannel(channelId: channelId);
      data = channel.toJson();
    } on Exception catch (_) {}
  }
  if (data == null || !context.mounted) {
    return;
  }
  await showDebugBottomSheet(context, title: title, data: data);
}
