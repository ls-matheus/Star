// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart' hide Message;
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/friends/providers/blocked_user_ids_provider.dart';
import 'package:star_app/features/notifications/presentation/recent_mentions_page.dart';
import 'package:star_app/features/notifications/presentation/widgets/mentions_empty_state.dart';
import 'package:star_app/features/notifications/providers/notification_stream_providers.dart';
import 'package:star_app/features/notifications/providers/notifications_providers.dart';
import 'package:star_app/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../helpers/core_test_provider_overrides.dart';
import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_l10n.dart';

void main() {
  testWidgets('RecentMentionsPage renders title and mentions body', (
    WidgetTester tester,
  ) async {
    final StarDatabase db = openTestDatabase();
    await tester.pumpWidget(
      _wrap(
        db: db,
        overrides: <Override>[
          mentionFeedCoordinatorProvider.overrideWith(
            _FetchedMentionFeedCoordinator.new,
          ),
          notificationMentionFeedStreamProvider.overrideWith(
            (Ref ref) => Stream<List<NotificationMentionFeedData>>.value(
              const <NotificationMentionFeedData>[],
            ),
          ),
        ],
        child: const RecentMentionsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mentions'), findsOneWidget);
    expect(find.byType(MentionsEmptyState), findsOneWidget);
    await releaseTestWidgetTree(tester);
  });

  testWidgets('mentions from blocked authors stay out of the feed', (
    WidgetTester tester,
  ) async {
    final StarDatabase db = openTestDatabase();
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(id: 'channel-1', guildId: '', name: 'general'),
    );
    for (final (String id, String authorId, String content)
        in <(String, String, String)>[
          ('2001', 'friend', 'friend mention'),
          ('2002', 'blocked', 'blocked mention'),
        ]) {
      await db.messageDao.upsertMessage(
        Message(
          id: id,
          channelId: 'channel-1',
          authorId: authorId,
          authorName: authorId,
          content: content,
          timestamp: DateTime.utc(2026, 10, 15, 12),
        ).toCompanion(),
      );
    }
    await tester.pumpWidget(
      _wrap(
        db: db,
        blockedUserIds: const <String>{'blocked'},
        overrides: <Override>[
          mentionFeedCoordinatorProvider.overrideWith(
            _FetchedMentionFeedCoordinator.new,
          ),
          notificationMentionFeedStreamProvider.overrideWith(
            (Ref ref) => Stream<List<NotificationMentionFeedData>>.value(
              const <NotificationMentionFeedData>[
                NotificationMentionFeedData(
                  messageId: '2002',
                  channelId: 'channel-1',
                  ordinal: 0,
                ),
                NotificationMentionFeedData(
                  messageId: '2001',
                  channelId: 'channel-1',
                  ordinal: 1,
                ),
              ],
            ),
          ),
        ],
        child: const RecentMentionsPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('friend mention', findRichText: true),
      findsWidgets,
    );
    expect(
      find.textContaining('blocked mention', findRichText: true),
      findsNothing,
    );

    await releaseTestWidgetTree(tester);
  });
}

class _FetchedMentionFeedCoordinator extends MentionFeedCoordinator {
  @override
  MentionFeedUiState build() => MentionFeedUiState(fetched: true);
}

Widget _wrap({
  required StarDatabase db,
  required List<Override> overrides,
  required Widget child,
  Set<String> blockedUserIds = const <String>{},
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: coreTestProviderOverrides(
      database: db,
      extra: <Override>[
        blockedUserIdsProvider.overrideWithValue(blockedUserIds),
        ...overrides,
      ],
    ),
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}
