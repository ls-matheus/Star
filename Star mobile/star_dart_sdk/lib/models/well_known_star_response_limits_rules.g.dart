// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'well_known_star_response_limits_rules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WellKnownStarResponseLimitsRules _$WellKnownStarResponseLimitsRulesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WellKnownStarResponseLimitsRules', json, (
  $checkedConvert,
) {
  final val = WellKnownStarResponseLimitsRules(
    id: $checkedConvert('id', (v) => v as String? ?? ''),
    overrides: $checkedConvert(
      'overrides',
      (v) =>
          (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as num)) ??
          {},
    ),
    filters: $checkedConvert(
      'filters',
      (v) => v == null
          ? null
          : WellKnownStarResponseLimitsRulesFilters.fromJson(
              v as Map<String, dynamic>,
            ),
    ),
  );
  return val;
});

Map<String, dynamic> _$WellKnownStarResponseLimitsRulesToJson(
  WellKnownStarResponseLimitsRules instance,
) => <String, dynamic>{
  'id': instance.id,
  'filters': ?instance.filters,
  'overrides': instance.overrides,
};
