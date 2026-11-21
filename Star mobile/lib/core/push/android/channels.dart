import 'dart:ui' show Color;

import 'package:star_app/core/push/notification/localization.dart';
import 'package:star_app/core/push/notification/payload.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

const String kAndroidPushMessageChannelId = 'star_messages';
const String kAndroidPushDirectMessageChannelId = 'star_direct_messages';
const String kAndroidPushForumThreadCreatedChannelId =
    'star_forum_thread_created';
const String kAndroidPushSilentMessageChannelId = 'star_messages_silent';
const String kAndroidPushSilentDirectMessageChannelId =
    'star_direct_messages_silent';

const String kAndroidPushNotificationIcon = '@drawable/ic_stat_star';
const Color kAndroidPushAccentColor = Color(0xFF4641D9);

String androidPushChannelId(
  Map<String, String> payload, {
  bool soundEnabled = true,
}) {
  if (isDmPushPayload(payload)) {
    return soundEnabled
        ? kAndroidPushDirectMessageChannelId
        : kAndroidPushSilentDirectMessageChannelId;
  }
  if (!soundEnabled) {
    return kAndroidPushSilentMessageChannelId;
  }
  if (isForumThreadCreatedPushPayload(payload)) {
    return kAndroidPushForumThreadCreatedChannelId;
  }
  return kAndroidPushMessageChannelId;
}

String androidPushChannelName(
  Map<String, String> payload, {
  bool soundEnabled = true,
}) {
  final StarLocalizations l10n = pushNotificationLocalizations();
  if (isDmPushPayload(payload)) {
    return soundEnabled
        ? l10n.notificationChannelDirectMessages
        : l10n.notificationChannelDirectMessagesSilent;
  }
  if (!soundEnabled) {
    return l10n.notificationChannelMessagesSilent;
  }
  if (isForumThreadCreatedPushPayload(payload)) {
    return l10n.notificationChannelForumPosts;
  }
  return l10n.notificationChannelMessages;
}
