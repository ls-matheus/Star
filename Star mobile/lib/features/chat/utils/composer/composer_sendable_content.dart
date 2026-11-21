import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:star_markdown/star_markdown.dart';

bool composerHasSendableContent(
  WidgetRef ref,
  String channelId,
  String wireText,
) {
  final bool hasPendingUploads = ref
      .read(cloudUploadControllerProvider(readAccountUserId(ref), channelId))
      .items
      .isNotEmpty;
  return composerHasSendableContentFromParts(
    channelId: channelId,
    wireText: wireText,
    hasPendingUploads: hasPendingUploads,
  );
}

bool composerHasSendableContentFromParts({
  required String channelId,
  required String wireText,
  required bool hasPendingUploads,
}) {
  if (channelId.isEmpty) {
    return false;
  }
  return hasVisibleContent(wireText) || hasPendingUploads;
}
