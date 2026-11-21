import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/members/domain/member.dart';
import 'package:riverpod/riverpod.dart';

/// Fetches a single role by ID from the local database.
// ignore: specify_nonobvious_property_types, public Riverpod family type is intentionally inferred.
final roleByIdProvider = FutureProvider.autoDispose.family<MemberRole?, String>(
  (ref, id) async {
    final db = ref.watch(starDatabaseProvider);
    final row = await db.roleDao.getRoleById(id);
    return row == null ? null : MemberRole.fromRow(row);
  },
);
