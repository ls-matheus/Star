import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate, TableUpdateQuery, Value;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/gateway/gateway_event_handler.dart';
import 'package:star_app/core/gateway/presence_store.dart';
import 'package:star_dart/gateway.dart';

import '../../helpers/open_test_database.dart';

PresenceUpdateBulkEvent _bulk(String userId, String status) {
  return PresenceUpdateBulkEvent(
    presences: <Map<String, dynamic>>[
      <String, dynamic>{
        'user': <String, dynamic>{'id': userId},
        'status': status,
      },
    ],
  );
}

void main() {
  Future<StarDatabase> databaseWithOnlineUser() async {
    final StarDatabase database = openTestDatabase();
    await database.userDao.upsertUser(
      UsersCompanion.insert(
        id: 'u1',
        username: 'u1',
      ).copyWith(status: const Value('online')),
    );
    await pumpEventQueue();
    return database;
  }

  test(
    'PRESENCE_UPDATE_BULK with stored values leaves users watchers silent',
    () async {
      final StarDatabase database = await databaseWithOnlineUser();

      fakeAsync((FakeAsync async) {
        final GatewayEventHandler handler = GatewayEventHandler(
          database: database,
          currentUserId: 'me',
        );
        final List<Set<TableUpdate>> emissions = <Set<TableUpdate>>[];
        final StreamSubscription<Set<TableUpdate>> sub = database
            .tableUpdates(TableUpdateQuery.onTable(database.users))
            .listen(emissions.add);

        unawaited(handler.handle(_bulk('u1', 'online')));
        async
          ..elapse(const Duration(seconds: 1))
          ..flushMicrotasks();

        expect(emissions, isEmpty);
        unawaited(sub.cancel());
        handler.dispose();
      });
    },
  );

  test(
    'PRESENCE_UPDATE_BULK with a new status updates presence without touching users',
    () async {
      final StarDatabase database = await databaseWithOnlineUser();

      fakeAsync((FakeAsync async) {
        final GatewayEventHandler handler = GatewayEventHandler(
          database: database,
          currentUserId: 'me',
        );
        final List<Set<TableUpdate>> emissions = <Set<TableUpdate>>[];
        final StreamSubscription<Set<TableUpdate>> sub = database
            .tableUpdates(TableUpdateQuery.onTable(database.users))
            .listen(emissions.add);

        unawaited(handler.handle(_bulk('u1', 'dnd')));
        async
          ..elapse(const Duration(seconds: 1))
          ..flushMicrotasks();

        expect(emissions, isEmpty);
        expect(presenceStoreFor(database)['u1']?.status, 'dnd');
        unawaited(sub.cancel());
        handler.dispose();
      });
    },
  );
}
