import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/dm/data/dm_repository.dart';
import 'package:star_app/features/guilds/data/guild_user_settings_repository.dart';
import 'package:star_dart/export.dart';

import '../../../helpers/open_test_database.dart';

ProviderContainer _createDmTestContainer(StarDatabase db, Dio dio) {
  return ProviderContainer(
    overrides: [
      starDatabaseProvider.overrideWithValue(db),
      starClientProvider.overrideWithValue(StarClient(dio)),
    ],
  );
}

DmRepository _createDmRepository(StarDatabase db, Dio dio) {
  final container = _createDmTestContainer(db, dio);
  return DmRepository(
    container.read(starClientProvider),
    db,
    container.read(guildUserSettingsRepositoryProvider),
  );
}

void main() {
  group('pinDm / unpinDm', () {
    late StarDatabase db;
    late Dio dio;

    setUp(() {
      db = openTestDatabase();
      dio = Dio(BaseOptions(baseUrl: 'https://api.star.invalid/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                if (options.method == 'PUT' &&
                    options.path.endsWith('/users/@me/channels/dm-2/pin')) {
                  handler.resolve(
                    Response<void>(requestOptions: options, statusCode: 204),
                  );
                  return;
                }
                if (options.method == 'DELETE' &&
                    options.path.endsWith('/users/@me/channels/dm-2/pin')) {
                  handler.resolve(
                    Response<void>(requestOptions: options, statusCode: 204),
                  );
                  return;
                }
                handler.reject(
                  DioException(
                    requestOptions: options,
                    message:
                        'Unexpected request: ${options.method} ${options.path}',
                  ),
                );
              },
        ),
      );
    });

    test('updates pinned_dms locally after pin API succeeds', () async {
      await db.pinnedDmsDao.replaceAll([
        const PinnedDmsTableCompanion(
          channelId: Value('dm-1'),
          position: Value(0),
        ),
      ]);

      final DmRepository repo = _createDmRepository(db, dio);
      await repo.pinDm('dm-2');

      final pinnedDms = await db.pinnedDmsDao.getPinnedDms();
      expect(pinnedDms, hasLength(2));
      expect(pinnedDms[0].channelId, 'dm-1');
      expect(pinnedDms[1].channelId, 'dm-2');
    });

    test('updates pinned_dms locally after unpin API succeeds', () async {
      await db.pinnedDmsDao.replaceAll([
        const PinnedDmsTableCompanion(
          channelId: Value('dm-1'),
          position: Value(0),
        ),
        const PinnedDmsTableCompanion(
          channelId: Value('dm-2'),
          position: Value(1),
        ),
      ]);

      final DmRepository repo = _createDmRepository(db, dio);
      await repo.unpinDm('dm-2');

      final pinnedDms = await db.pinnedDmsDao.getPinnedDms();
      expect(pinnedDms, hasLength(1));
      expect(pinnedDms.single.channelId, 'dm-1');
    });
  });
}
