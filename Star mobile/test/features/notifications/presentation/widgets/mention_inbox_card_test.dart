import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/permissions/permission.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:star_app/features/dm/providers/dm_view_model.dart';
import 'package:star_app/features/notifications/presentation/widgets/mention_inbox_card.dart';
import 'package:star_app/material_ui.dart';

import '../../../../helpers/message_item_test_overrides.dart';
import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

final StarLocalizations _l10n = testL10n;

const String _channelId = 'channel-1';

Future<List<Message>> _pumpCard(
  WidgetTester tester, {
  required int permissionBits,
}) async {
  final List<Message> replies = <Message>[];
  final Message message = Message(
    id: 'message-1',
    channelId: _channelId,
    authorId: 'author-1',
    authorName: 'Author',
    content: 'hello',
    timestamp: DateTime.utc(2026),
  );
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...messageItemTestProviderOverrides(),
        starDatabaseProvider.overrideWithValue(openTestDatabase()),
        currentUserIdProvider.overrideWithValue('test-user'),
        dmViewModelProvider.overrideWith(_EmptyDmViewModel.new),
        channelMessagePermissionsProvider(_channelId).overrideWith(
          (Ref ref) => channelMessagePermissionsFromBits(
            bits: permissionBits,
            channelType: ChannelType.guildText,
          ),
        ),
      ],
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: MentionInboxCard(
            messageId: message.id,
            message: message,
            header: null,
            previewGuildId: 'guild-1',
            onJump: (_) {},
            onRemove: (_) {},
            onReply: replies.add,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return replies;
}

void main() {
  testWidgets('offers a reply when the composer could send', (
    WidgetTester tester,
  ) async {
    final List<Message> replies = await _pumpCard(
      tester,
      permissionBits:
          Permission.viewChannel.value | Permission.sendMessages.value,
    );

    await tester.tap(findTestText(_l10n.notificationsSendReply));
    expect(replies, hasLength(1));

    await releaseTestWidgetTree(tester);
  });

  testWidgets('hides the reply when the composer is read-only', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, permissionBits: Permission.viewChannel.value);

    expect(findTestText(_l10n.notificationsSendReply), findsNothing);

    await releaseTestWidgetTree(tester);
  });
}

class _EmptyDmViewModel extends DmViewModel {
  @override
  DmViewState build() => const DmViewState(
    conversations: [],
    friendsList: [],
    activeTab: FriendsTab.online,
    searchQuery: '',
  );
}
