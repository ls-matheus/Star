import 'package:drift/drift.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/database/tables/rtc_regions.dart';

part 'rtc_regions_dao.g.dart';

@DriftAccessor(tables: [RtcRegionsTable])
class RtcRegionsDao extends DatabaseAccessor<StarDatabase>
    with _$RtcRegionsDaoMixin {
  RtcRegionsDao(super.attachedDatabase);

  Future<void> clearAll() => delete(rtcRegionsTable).go();
}
