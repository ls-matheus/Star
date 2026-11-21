import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_ready_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/router/route_state_providers.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/core/utils/channel_jump_link.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/utils/navigation/link_channel_navigator.dart';
import 'package:star_app/features/chat/utils/channel_jump_navigator.dart';
import 'package:star_app/features/mature_content/domain/mature_content_types.dart';
import 'package:star_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:star_app/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/open_test_database.dart';

void main() {
  const String guildId = '111111111111111111';
  const String textChannelId = '222222222222222222';
  const String linkChannelId = '333333333333333333';
  const String loopChannelId = '444444444444444444';
  const String textChannelUrl =
      'https://web.star.invalid/channels/$guildId/$textChannelId';

  late db.StarDatabase database;
  late GoRouter router;
  late List<String> launched;

  String currentPath() => router.routeInformationProvider.value.uri.path;

  Future<void> insertChannel({
    required String id,
    required String name,
    required ChannelType type,
    String? url,
  }) {
    return database.channelDao.upsertChannel(
      db.ChannelsCompanion.insert(
        id: id,
        guildId: guildId,
        name: name,
        type: Value<int>(type.wireValue),
        url: Value<String?>(url),
      ),
    );
  }

  Future<Channel> channelFromDb(String id) async {
    final db.Channel? row = await database.channelDao.getChannelById(id);
    return Channel.fromRow(row!);
  }

  Future<(BuildContext, ProviderContainer)> pumpHost(
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        starDatabaseProvider.overrideWithValue(database),
        activeChannelIdProvider.overrideWithValue(null),
        starRouterProvider.overrideWithValue(router),
        for (final String id in <String>[
          textChannelId,
          linkChannelId,
          loopChannelId,
        ])
          matureContentGateReasonProvider(id).overrideWith(
            (ref) => Future<MatureContentGateReason>.value(
              MatureContentGateReason.none,
            ),
          ),
      ],
    );
    addTearDown(container.dispose);
    container.read(gatewayReadyProvider.notifier).setReady();
    launched = <String>[];
    const MethodChannel launcher = MethodChannel(
      'plugins.flutter.io/url_launcher',
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(launcher, (
      MethodCall call,
    ) async {
      if (call.method == 'launch') {
        launched.add(
          (call.arguments as Map<Object?, Object?>)['url']! as String,
        );
      }
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        launcher,
        null,
      ),
    );
    final StarColorTheme colorTheme = buildDarkColorTheme();
    late BuildContext captured;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
          home: Builder(
            builder: (BuildContext context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return (captured, container);
  }

  setUp(() async {
    database = openTestDatabase();
    router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, _) => const Text('home')),
        GoRoute(
          path: '/channels/:guildId/:channelId',
          builder: (_, _) => const Text('channel'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await insertChannel(
      id: textChannelId,
      name: 'general',
      type: ChannelType.guildText,
    );
  });

  testWidgets('a link channel pointing at a Star channel opens it in-app', (
    tester,
  ) async {
    await insertChannel(
      id: linkChannelId,
      name: 'rules-link',
      type: ChannelType.guildLink,
      url: textChannelUrl,
    );
    final (BuildContext context, ProviderContainer container) = await pumpHost(
      tester,
    );
    final Channel linkChannel = (await tester.runAsync<Channel>(
      () => channelFromDb(linkChannelId),
    ))!;

    final bool opened = await tryOpenLinkChannel(
      context: context,
      container: container,
      channel: linkChannel,
      skipGate: true,
    );
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    expect(opened, isTrue);
    expect(currentPath(), '/channels/$guildId/$textChannelId');
    expect(launched, isEmpty);
  });

  testWidgets('a channel link to a link channel with a Star channel URL '
      'opens the target in-app', (tester) async {
    await insertChannel(
      id: linkChannelId,
      name: 'rules-link',
      type: ChannelType.guildLink,
      url: textChannelUrl,
    );
    final (BuildContext context, ProviderContainer container) = await pumpHost(
      tester,
    );

    await tester.runAsync(
      () => navigateToChannelJumpLink(
        container: container,
        context: context,
        link: const ChannelJumpLink(scope: guildId, channelId: linkChannelId),
      ),
    );
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    expect(currentPath(), '/channels/$guildId/$textChannelId');
    expect(launched, isEmpty);
  });

  testWidgets('link channels pointing at each other do not jump forever', (
    tester,
  ) async {
    await insertChannel(
      id: linkChannelId,
      name: 'a',
      type: ChannelType.guildLink,
      url: 'https://web.star.invalid/channels/$guildId/$loopChannelId',
    );
    await insertChannel(
      id: loopChannelId,
      name: 'b',
      type: ChannelType.guildLink,
      url: 'https://web.star.invalid/channels/$guildId/$linkChannelId',
    );
    final (BuildContext context, ProviderContainer container) = await pumpHost(
      tester,
    );
    final Channel linkChannel = (await tester.runAsync<Channel>(
      () => channelFromDb(linkChannelId),
    ))!;

    await tryOpenLinkChannel(
      context: context,
      container: container,
      channel: linkChannel,
      skipGate: true,
    );
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    expect(currentPath(), '/');
    expect(launched, <String>[
      'https://web.star.invalid/channels/$guildId/$linkChannelId',
    ]);
  });
}
