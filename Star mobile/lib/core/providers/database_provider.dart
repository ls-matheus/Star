import 'package:star_app/core/database/star_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
StarDatabase starDatabase(Ref ref) {
  final db = StarDatabase();
  ref.onDispose(db.close);
  return db;
}
