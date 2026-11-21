import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:star_app/core/database/query_stats_interceptor.dart';
import 'package:star_app/core/database/sqlite_pragmas.dart';
import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/talker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const int kSqliteReadPoolSize = 2;

QueryExecutor openStarSqliteConnection() {
  final QueryExecutor executor = LazyDatabase(() async {
    final File file = await _resolveDatabaseFile();
    await file.parent.create(recursive: true);
    return NativeDatabase.createInBackground(
      file,
      setup: driftSqliteSetup(isMobile: isStarNativeMobileOs),
      readPool: kSqliteReadPoolSize,
    );
  });
  if (!kStarQueryStatsEnabled) {
    return executor;
  }
  return executor.interceptWith(QueryStatsInterceptor(log: talker.info));
}

const String _iosDatabaseFileName = 'star.sqlite';
const List<String> _sqliteFileSuffixes = <String>[
  '-wal',
  '-shm',
  '-journal',
  '',
];

Future<File> _resolveDatabaseFile() async {
  if (isStarDesktopOs) {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'star_app', 'star.db'));
  }
  if (Platform.isIOS) {
    final Directory support = await getApplicationSupportDirectory();
    final Directory documents = await getApplicationDocumentsDirectory();
    return await moveLegacyIosDatabase(
      legacyDirectory: documents,
      databaseDirectory: Directory(p.join(support.path, 'database')),
    );
  }
  final Directory dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, 'star.sqlite'));
}

@visibleForTesting
Future<File> moveLegacyIosDatabase({
  required Directory legacyDirectory,
  required Directory databaseDirectory,
}) async {
  final File target = File(
    p.join(databaseDirectory.path, _iosDatabaseFileName),
  );
  final File legacy = File(p.join(legacyDirectory.path, _iosDatabaseFileName));
  if (target.existsSync() || !legacy.existsSync()) {
    return target;
  }
  await databaseDirectory.create(recursive: true);
  for (final String suffix in _sqliteFileSuffixes) {
    final File source = File('${legacy.path}$suffix');
    if (source.existsSync()) {
      await source.rename('${target.path}$suffix');
    }
  }
  return target;
}
