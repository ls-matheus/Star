import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/notifications/data/unread_inbox_card_cache.dart';
import 'package:star_app/features/notifications/data/unread_inbox_card_meta.dart';
import 'package:star_app/features/notifications/data/unread_inbox_view.dart';
import 'package:star_app/features/notifications/domain/unread_inbox_entry.dart';
import 'package:star_app/features/notifications/presentation/widgets/unread_channel_inbox_card.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

UnreadChannelInboxCard _card() {
  return UnreadChannelInboxCard(
    row: UnreadInboxRow(
      entry: const UnreadInboxEntry(
        channelId: 'channel-1',
        guildId: 'guild-1',
        isDm: false,
        mentionCount: 0,
        isCollapsed: true,
        recencyComparator: 1,
        ackMessageId: null,
        lastMessageId: null,
      ),
      data: UnreadInboxCardData(
        cacheKey: 'channel-1',
        meta: UnreadInboxCardMeta.empty(),
        messages: const [],
        hasMoreUnread: false,
      ),
      collapsed: true,
      read: false,
    ),
    onCollapsedChanged: (_) {},
    onDismissed: () {},
  );
}

Future<GoRouter> _pumpInbox(
  WidgetTester tester, {
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final StarDatabase db = openTestDatabase();
  await db.channelDao.upsertChannel(
    ChannelsCompanion.insert(
      id: 'channel-1',
      guildId: 'guild-1',
      name: 'general',
    ),
  );

  final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            Scaffold(
              body: child,
              bottomNavigationBar: const SizedBox(
                height: 56,
                child: Text('bottom navigation'),
              ),
            ),
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                Scaffold(body: _card()),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/guild/:guildId',
        builder: (BuildContext context, GoRouterState state) =>
            const Scaffold(body: Text('guild settings route')),
      ),
    ],
  );
  addTearDown(router.dispose);

  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[starDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets(
    'bell opens channel notification settings without leaving the inbox',
    (WidgetTester tester) async {
      final GlobalKey<NavigatorState> rootNavigatorKey =
          GlobalKey<NavigatorState>();
      final GoRouter router = await _pumpInbox(
        tester,
        rootNavigatorKey: rootNavigatorKey,
      );

      await tester.tap(find.byIcon(PhosphorIconsBold.bellSimple));
      await tester.pumpAndSettle();

      expect(find.text('guild settings route'), findsNothing);
      expect(router.state.uri.toString(), '/');
      expect(find.text('Notification settings'), findsOneWidget);
      expect(find.text('Mute channel'), findsOneWidget);

      await releaseTestWidgetTree(tester);
    },
  );

  testWidgets('bell menu sheet covers the bottom navigation', (
    WidgetTester tester,
  ) async {
    final GlobalKey<NavigatorState> rootNavigatorKey =
        GlobalKey<NavigatorState>();
    await _pumpInbox(tester, rootNavigatorKey: rootNavigatorKey);

    await tester.tap(find.byIcon(PhosphorIconsBold.bellSimple));
    await tester.pumpAndSettle();

    expect(
      Navigator.of(tester.element(find.text('Mute channel'))),
      same(rootNavigatorKey.currentState),
    );

    await releaseTestWidgetTree(tester);
  });
}
