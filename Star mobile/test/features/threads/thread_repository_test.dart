import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_api_features.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/features/threads/data/threads_repository.dart';
import 'package:star_dart/export.dart';

import '../../helpers/open_test_database.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final List<String> paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

const Map<String, Object?> _threadJson = <String, Object?>{
  'id': 't1',
  'type': 11,
  'guild_id': 'g1',
  'parent_id': 'c1',
  'name': 'thread',
};

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter({this.channel = _threadJson});

  final Map<String, Object?> channel;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(channel),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('capability markers are advertised', () {
    expect(
      buildStarApiFeaturesHeaderValue().split(', '),
      contains('channel_threads'),
    );
    expect(kGatewayChannelThreads, 1 << 2);
  });

  test('a no-op thread settings update answers 204 without failing', () async {
    final _RecordingAdapter adapter = _RecordingAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    final StarDatabase database = openTestDatabase();
    final ThreadsRepository repository = ThreadsRepository(
      StarClient(dio),
      database,
    );

    final ThreadMemberResponse? member = await repository.updateSettings(
      guildId: 'g1',
      threadId: 't1',
      body: ThreadMemberSettingsRequest(flags: 2),
    );

    expect(member, isNull);
    expect(adapter.paths, <String>['/channels/t1/thread-members/@me/settings']);
    expect(await database.threadDao.getMember('t1'), isNull);
  });

  test('a thread settings update stores the returned member', () async {
    final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _JsonAdapter(
        channel: <String, Object?>{
          'id': 't1',
          'user_id': 'u1',
          'join_timestamp': '2026-09-29T00:00:00.000Z',
          'flags': 2,
        },
      );
    final StarDatabase database = openTestDatabase();
    final ThreadsRepository repository = ThreadsRepository(
      StarClient(dio),
      database,
    );

    final ThreadMemberResponse? member = await repository.updateSettings(
      guildId: 'g1',
      threadId: 't1',
      body: ThreadMemberSettingsRequest(flags: 2),
    );

    expect(member?.flags, 2);
    expect(await database.threadDao.getMember('t1'), isNotNull);
  });

  test('a fetch stores only threads of the route guild', () async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(
      () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
    );
    Future<StarDatabase> fetchWith(Map<String, Object?> channel) async {
      final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = _JsonAdapter(channel: channel);
      final StarDatabase database = openTestDatabase();
      await ThreadsRepository(
        StarClient(dio),
        database,
      ).fetch(guildId: 'g1', threadId: 't1');
      return database;
    }

    final StarDatabase stored = await fetchWith(_threadJson);
    expect(await stored.channelDao.getChannelById('t1'), isNotNull);

    final StarDatabase otherGuild = await fetchWith(<String, Object?>{
      ..._threadJson,
      'guild_id': 'g2',
    });
    expect(await otherGuild.channelDao.getChannelById('t1'), isNull);

    final StarDatabase textChannel = await fetchWith(<String, Object?>{
      ..._threadJson,
      'type': 0,
    });
    expect(await textChannel.channelDao.getChannelById('t1'), isNull);
  });
}
