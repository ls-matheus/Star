import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/channels/data/ack_batcher.dart';
import 'package:star_app/features/channels/providers/ack_batcher_provider.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/shared/services/guild_member_hydration_service.dart';
import 'package:star_app/shared/utils/snowflake_time.dart';
import 'package:star_dart/export.dart';

import '../../../../helpers/noop_guild_member_hydration_service.dart';
import '../../../../helpers/open_test_database.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

Map<String, Object?> _messageJson({
  required String id,
  required String channelId,
  required String authorId,
}) => <String, Object?>{
  'id': id,
  'channel_id': channelId,
  'author': <String, Object?>{
    'id': authorId,
    'username': 'user-$authorId',
    'discriminator': '0001',
    'global_name': null,
    'avatar': null,
    'avatar_color': null,
    'flags': 0,
  },
  'type': 0,
  'flags': 0,
  'tts': false,
  'content': 'message $id',
  'timestamp': dateTimeFromUserSnowflakeOrNull(id)!.toIso8601String(),
  'pinned': false,
  'mention_everyone': false,
  'mentions': <Object?>[],
  'mention_roles': <Object?>[],
};

void main() {
  test(
    'jumpToFirstUnread targets the loaded first unread without fetching',
    () async {
      final db = openTestDatabase();

      final DateTime base = DateTime.utc(2026, 5, 20, 10);
      final List<String> ids = List<String>.generate(
        50,
        (i) => _snowflakeForUtc(base.add(Duration(minutes: i))),
      );
      final String ackId = ids[47];
      final String ownAfterAckId = ids[48];
      final List<Map<String, Object?>> window = <Map<String, Object?>>[
        for (final id in ids)
          _messageJson(
            id: id,
            channelId: 'channel-1',
            authorId: id == ownAfterAckId ? 'me' : 'other',
          ),
      ];

      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(ids.last),
        ),
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: const Value('channel-1'),
          lastMessageId: Value(ackId),
          mentionCount: const Value(0),
        ),
      );

      final adapter = _JumpAdapter(
        initialMessages: window,
        aroundMessages: window,
      );
      final container = _container(db, adapter);
      addTearDown(container.dispose);

      final notifier = container.read(chatViewModelProvider.notifier);
      await notifier.switchChannel('channel-1');
      await _flushAsync();

      final ChatViewState loaded = container.read(chatViewModelProvider);
      expect(loaded.hasMoreMessages, isTrue);
      expect(loaded.messages.map((m) => m.id), contains(ackId));
      final int fetchesAfterLoad = adapter.messageRequestUris.length;

      adapter.failMessageFetches = true;
      await notifier.jumpToFirstUnread();
      await _flushAsync();

      final ChatViewState state = container.read(chatViewModelProvider);
      expect(state.scrollToMessageSignal?.$1, ownAfterAckId);
      expect(state.highlightedMessageId, ownAfterAckId);
      expect(adapter.messageRequestUris.length, fetchesAfterLoad);
      expect(adapter.aroundQueries, [ackId]);
    },
  );

  test('jumpToFirstUnread lands on the nearest newer message from the open '
      'around window without refetching', () async {
    final db = openTestDatabase();

    final String ackId = _snowflakeForUtc(DateTime.utc(2026, 5, 19, 9));
    final String nearestNewerId = _snowflakeForUtc(
      DateTime.utc(2026, 5, 19, 10),
    );
    final String aroundNewerId = _snowflakeForUtc(
      DateTime.utc(2026, 5, 19, 11),
    );
    final DateTime base = DateTime.utc(2026, 5, 20, 10);
    final List<String> windowIds = List<String>.generate(
      50,
      (i) => _snowflakeForUtc(base.add(Duration(minutes: i))),
    );
    final List<Map<String, Object?>> window = <Map<String, Object?>>[
      for (final id in windowIds)
        _messageJson(id: id, channelId: 'channel-1', authorId: 'other'),
    ];
    final List<Map<String, Object?>> aroundPage = <Map<String, Object?>>[
      _messageJson(id: ackId, channelId: 'channel-1', authorId: 'other'),
      _messageJson(
        id: nearestNewerId,
        channelId: 'channel-1',
        authorId: 'other',
      ),
      _messageJson(
        id: aroundNewerId,
        channelId: 'channel-1',
        authorId: 'other',
      ),
    ];

    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(windowIds.last),
      ),
    );
    await db.readStateDao.upsertReadState(
      ReadStatesCompanion(
        channelId: const Value('channel-1'),
        lastMessageId: Value(ackId),
        mentionCount: const Value(0),
      ),
    );

    final adapter = _JumpAdapter(
      initialMessages: window,
      aroundMessages: aroundPage,
    );
    final container = _container(db, adapter);
    addTearDown(container.dispose);

    final notifier = container.read(chatViewModelProvider.notifier);
    await notifier.switchChannel('channel-1');
    await _flushAsync();

    expect(container.read(chatViewModelProvider).hasMoreMessages, isTrue);
    expect(adapter.aroundQueries, [ackId]);
    final int fetchesAfterLoad = adapter.messageRequestUris.length;
    adapter.failMessageFetches = true;

    await notifier.jumpToFirstUnread();
    await _flushAsync();

    expect(adapter.aroundQueries, [ackId]);
    final ChatViewState state = container.read(chatViewModelProvider);
    expect(state.messages.map((m) => m.id), [
      ackId,
      nearestNewerId,
      aroundNewerId,
    ]);
    expect(state.scrollToMessageSignal?.$1, nearestNewerId);
    expect(state.highlightedMessageId, nearestNewerId);
    expect(adapter.messageRequestUris.length, fetchesAfterLoad);
  });
}

ProviderContainer _container(StarDatabase db, _JumpAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.star.invalid/v1'))
    ..httpClientAdapter = adapter;
  final client = StarClient(dio, baseUrl: 'https://api.star.invalid/v1');
  return ProviderContainer(
    overrides: [
      starDatabaseProvider.overrideWithValue(db),
      appUiForegroundProvider.overrideWithValue(true),
      starDioProvider.overrideWithValue(dio),
      starClientProvider.overrideWithValue(client),
      currentUserIdProvider.overrideWithValue('me'),
      ackBatcherProvider.overrideWith((ref) {
        final batcher = AckBatcher(client: client, batchDelay: Duration.zero);
        ref.onDispose(() {
          unawaited(batcher.dispose());
        });
        return batcher;
      }),
      guildMemberHydrationServiceProvider.overrideWithValue(
        NoopGuildMemberHydrationService(database: db),
      ),
    ],
  );
}

Future<void> _flushAsync() async {
  for (var i = 0; i < 8; i++) {
    await pumpEventQueue();
  }
}

class _JumpAdapter implements HttpClientAdapter {
  _JumpAdapter({this.initialMessages = const [], this.aroundMessages});

  final List<Map<String, Object?>> initialMessages;
  final List<Map<String, Object?>>? aroundMessages;
  final List<Uri> messageRequestUris = [];
  final List<String> aroundQueries = [];
  bool failMessageFetches = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bool isMessages = RegExp(
      r'/channels/[^/]+/messages$',
    ).hasMatch(options.uri.path);
    if (options.method == 'GET' && isMessages) {
      messageRequestUris.add(options.uri);
      if (failMessageFetches) {
        return ResponseBody.fromString('unexpected message fetch', 500);
      }
      final String? around = options.uri.queryParameters['around'];
      if (around != null) {
        aroundQueries.add(around);
        return _json((aroundMessages ?? const []).reversed.toList());
      }
      return _json(initialMessages.reversed.toList());
    }
    if (options.method == 'POST' &&
        (options.uri.path.endsWith('/ack') ||
            options.uri.path.endsWith('/read-states/ack-bulk'))) {
      return ResponseBody.fromString('', 204, statusMessage: 'No Content');
    }
    return ResponseBody.fromString('Not found', 404);
  }

  ResponseBody _json(Object data) => ResponseBody.fromString(
    jsonEncode(data),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  void close({bool force = false}) {}
}
