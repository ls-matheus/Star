// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'well_known_star_response_limits_rules_filters.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WellKnownStarResponseLimitsRulesFilters
_$WellKnownStarResponseLimitsRulesFiltersFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WellKnownStarResponseLimitsRulesFilters', json, (
  $checkedConvert,
) {
  final val = WellKnownStarResponseLimitsRulesFilters(
    traits: $checkedConvert(
      'traits',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
    guildFeatures: $checkedConvert(
      'guildFeatures',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$WellKnownStarResponseLimitsRulesFiltersToJson(
  WellKnownStarResponseLimitsRulesFilters instance,
) => <String, dynamic>{
  'traits': ?instance.traits,
  'guildFeatures': ?instance.guildFeatures,
};
