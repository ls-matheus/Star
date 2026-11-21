import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/deep_links/app_page_links.dart';
import 'package:star_app/core/deep_links/deep_link_path_policy.dart';
import 'package:star_app/core/deep_links/user_settings_deep_link.dart';
import 'package:star_app/core/instance/instance_endpoints.dart';
import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/core/utils/channel_jump_link.dart';
import 'package:star_app/features/channels/utils/channel_mention_utils.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_alert.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_mention.dart';
import 'package:star_app/features/chat/utils/channel_jump_navigator.dart';
import 'package:star_app/features/chat/utils/messages/spoiler_utils.dart';
import 'package:star_app/features/emoji/presentation/sheets/emoji_info_bottom_sheet.dart';
import 'package:star_app/features/guilds/utils/invites/invite_link_navigator.dart';
import 'package:star_app/features/profile/presentation/user_profile_sheet.dart';
import 'package:star_app/features/settings/utils/user_settings/open_user_settings_deep_link.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/shared/external_links/external_link_handler.dart';
import 'package:star_app/shared/markdown/ansi_palette_from_context.dart';
import 'package:star_app/shared/markdown/message_markdown_settings.dart';
import 'package:star_app/shared/utils/emoji/emoji_registry.dart';
import 'package:star_app/shared/utils/emoji/emoji_utils.dart';
import 'package:star_markdown/star_markdown.dart';
import 'package:go_router/go_router.dart';

String _starAppLinkToHttps(String href) {
  if (href.startsWith('star://')) {
    final Uri uri = Uri.parse(href);
    return 'https://star.invalid${uri.path}';
  }
  if (href.startsWith('star:/')) {
    return 'https://star.invalid/${href.substring('star:/'.length)}';
  }
  if (href.startsWith('star:')) {
    return 'https://star.invalid/${href.substring('star:'.length)}';
  }
  return href;
}

final RegExp _userProfilePathPattern = RegExp(r'^/users/([0-9]{1,20})/?$');

Widget _starUserMentionBuilder(
  BuildContext context,
  String id,
  TextStyle style,
) {
  final MessageMarkdownBinding? binding = MessageMarkdownBinding.maybeOf(
    context,
  );
  return UserMention(
    userId: id,
    channelId: binding?.channelId,
    guildId: binding?.guildId,
    baseStyle: style,
  );
}

Widget _starChannelMentionBuilder(
  BuildContext context,
  String id,
  TextStyle style,
) {
  final MessageMarkdownBinding? binding = MessageMarkdownBinding.maybeOf(
    context,
  );
  return ChannelMention(
    channelId: id,
    fallback: findChannelMentionFallback(
      binding?.mentionChannels ?? const <MessageChannelMention>[],
      id,
    ),
    baseStyle: style,
  );
}

Widget _starRoleMentionBuilder(
  BuildContext context,
  String id,
  TextStyle style,
) {
  return RoleMention(roleId: id, baseStyle: style);
}

Widget _starEveryoneMentionBuilder(
  BuildContext context,
  String label,
  TextStyle style,
) {
  return TextMention(label: label, baseStyle: style);
}

Widget _starCommandMentionBuilder(
  BuildContext context,
  String command,
  String applicationId,
  TextStyle style,
) {
  return CommandMention(command: command, baseStyle: style);
}

Widget _starGuildNavigationMentionBuilder(
  BuildContext context,
  StarGuildNavigationType type,
  String? navigationId,
  TextStyle style,
) {
  return GuildNavigationMention(
    type: type,
    navigationId: navigationId,
    baseStyle: style,
  );
}

AppPageLinkAvailability _appPageLinkAvailability(BuildContext context) {
  final ProviderContainer container = ProviderScope.containerOf(
    context,
    listen: false,
  );
  final config = container.read(instanceRuntimeConfigProvider);
  return AppPageLinkAvailability(
    singleCommunity: config.singleCommunity,
    directMessagesDisabled: config.directMessagesDisabled,
  );
}

String _instanceWebAppBase() => InstanceEndpoints.webApp;

Widget? _starLinkWidgetBuilder(
  BuildContext context,
  String href,
  TextStyle style,
) {
  final UserSettingsDeepLinkTarget? settingsTarget = _parseSettingsDeepLinkHref(
    href,
  );
  if (settingsTarget != null) {
    return SettingsJumpLinkMention(target: settingsTarget, baseStyle: style);
  }
  final AppPageId? appPage = parseAppPageLink(
    href,
    instanceWebAppBase: _instanceWebAppBase(),
    availability: _appPageLinkAvailability(context),
  );
  if (appPage != null) {
    return AppPageJumpLinkMention(page: appPage, baseStyle: style);
  }
  final String resolvedHref = href.startsWith('star:')
      ? _starAppLinkToHttps(href)
      : href;
  final ChannelJumpLink? link = parseChannelJumpLink(resolvedHref);
  if (link == null) {
    return null;
  }
  return ChannelJumpLinkMention(link: link, baseStyle: style);
}

Future<void> _starOnTapLink(BuildContext context, String href) async {
  final Uri? starPath = parseStarAppLinkUri(href);
  if (starPath != null) {
    if (!context.mounted) {
      return;
    }
    final String path = normalizeDeepLinkPath(starPath.path);
    if (path.startsWith('/invite/') ||
        path.startsWith('/gift/') ||
        path.startsWith('/theme/')) {
      GoRouter.of(context).go(path);
      return;
    }
    final String? userId = _userProfilePathPattern.firstMatch(path)?.group(1);
    if (userId != null) {
      await StarUserProfileSheet.show(
        context,
        userId: userId,
        guildId: MessageMarkdownBinding.maybeOf(context)?.guildId,
      );
      return;
    }
    if (isUserSettingsDeepLinkPath(starPath)) {
      await openUserSettingsDeepLinkFromContext(
        context,
        parseUserSettingsDeepLink(starPath)!,
      );
      return;
    }
    final AppPageId? appPage = appPageIdForPath(
      starPath.path,
      availability: _appPageLinkAvailability(context),
    );
    if (appPage != null) {
      if (!context.mounted) {
        return;
      }
      navigateToAppPage(context, appPage);
      return;
    }
  }

  final String resolvedHref = href.startsWith('star:')
      ? _starAppLinkToHttps(href)
      : href;
  final AppPageId? appPage = parseAppPageLink(
    resolvedHref,
    instanceWebAppBase: _instanceWebAppBase(),
    availability: _appPageLinkAvailability(context),
  );
  if (appPage != null) {
    if (!context.mounted) {
      return;
    }
    navigateToAppPage(context, appPage);
    return;
  }

  final ChannelJumpLink? jump = parseChannelJumpLink(resolvedHref);
  if (jump != null) {
    if (!context.mounted) {
      return;
    }
    await navigateToChannelJumpLinkFromContext(
      context: context,
      link: jump,
      dismissCoveringPages: true,
    );
    return;
  }

  if (isInviteLink(href)) {
    if (!context.mounted) {
      return;
    }
    await handleInviteLinkTap(context, href);
    return;
  }

  await handleExternalLinkTap(context, href);
}

Widget _starAlertBuilder(
  BuildContext context,
  StarAlertType type,
  Widget body,
  TextStyle baseStyle,
) {
  return MessageAlert(
    type: switch (type) {
      StarAlertType.note => AlertType.note,
      StarAlertType.tip => AlertType.tip,
      StarAlertType.important => AlertType.important,
      StarAlertType.warning => AlertType.warning,
      StarAlertType.caution => AlertType.caution,
    },
    bodyWidget: body,
    baseStyle: baseStyle,
  );
}

void _starOnCopyCode(BuildContext ctx, String _) {
  ProviderScope.containerOf(ctx, listen: false)
      .read(toastProvider.notifier)
      .show(
        StarToast(
          message: StarLocalizations.of(ctx).copiedToClipboard,
          variant: StarToastVariant.success,
        ),
      );
}

StarMarkdownConfig createStarMarkdownConfig({
  BuildContext? context,
  bool revealSpoilers = false,
  StarSpoilerSyncController? spoilerSyncController,
  StarTimestampFormatter? timestampFormatter,
  StarSelectionContextMenuBuilder? selectionContextMenuBuilder,
  bool alwaysUnderlineLinks = false,
  bool dimStrikethroughText = true,
  bool animateCustomEmoji = true,
}) {
  return StarMarkdownConfig(
    unicodeEmojiUrlBuilder: getTwemojiUrl,
    customEmojiUrlBuilder: StarMediaUrl.customEmoji,
    unicodeEmojiMatcher: EmojiRegistry.unicodeEmojiMatcherSync,
    animateCustomEmoji: animateCustomEmoji,
    linkColor: context?.colors.textLink,
    blockquoteBorderColor: context?.colors.interactiveMuted,
    blockquoteTextColor: context?.colors.textChatMuted,
    alwaysUnderlineLinks: alwaysUnderlineLinks,
    dimStrikethroughText: dimStrikethroughText,
    inlineCodeBackgroundColor: context?.colors.bgCodeBlock,
    inlineCodeTextColor: context?.colors.textSecondary,
    codeTextStyle: context?.textStyles.codeText,
    ansiPalette: ansiPaletteFromContext(context),
    tableBorderColor: context?.colors.borderColor,
    tableHeaderBackgroundColor: context?.colors.bgTableHeader,
    tableHeaderTextColor: context?.colors.textPrimary,
    tableRowOddBackgroundColor: context?.colors.bgTableRowOdd,
    tableRowEvenBackgroundColor: context?.colors.bgTableRowEven,
    tableBorderRadius: context?.layout.radiusMd,
    internalLinkPattern: instanceChannelJumpLinkPattern(),
    userMentionBuilder: _starUserMentionBuilder,
    channelMentionBuilder: _starChannelMentionBuilder,
    roleMentionBuilder: _starRoleMentionBuilder,
    everyoneMentionBuilder: _starEveryoneMentionBuilder,
    commandMentionBuilder: _starCommandMentionBuilder,
    guildNavigationMentionBuilder: _starGuildNavigationMentionBuilder,
    linkWidgetBuilder: _starLinkWidgetBuilder,
    onTapLink: _starOnTapLink,
    spoilersInitiallyRevealed: revealSpoilers,
    spoilerSyncController: spoilerSyncController,
    spoilerSyncKeyNormalizer: normalizeSpoilerUrl,
    timestampFormatter: timestampFormatter,
    alertBuilder: _starAlertBuilder,
    onCopyCode: _starOnCopyCode,
    selectionContextMenuBuilder: selectionContextMenuBuilder,
    onEmojiLongPress: starMarkdownEmojiLongPressHandler,
  );
}

UserSettingsDeepLinkTarget? _parseSettingsDeepLinkHref(String href) {
  final Uri? starPath = parseStarAppLinkUri(href);
  if (starPath == null || !isUserSettingsDeepLinkPath(starPath)) {
    return null;
  }
  return parseUserSettingsDeepLink(starPath);
}
