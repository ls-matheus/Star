// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'well_known_star_response_limits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WellKnownStarResponseLimits _$WellKnownStarResponseLimitsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WellKnownStarResponseLimits', json, ($checkedConvert) {
  final val = WellKnownStarResponseLimits(
    version: $checkedConvert('version', (v) => v as num? ?? 0),
    traitDefinitions: $checkedConvert(
      'traitDefinitions',
      (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    ),
    rules: $checkedConvert(
      'rules',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) => WellKnownStarResponseLimitsRules.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    ),
    defaultsHash: $checkedConvert('defaultsHash', (v) => v as String? ?? ''),
  );
  return val;
});

Map<String, dynamic> _$WellKnownStarResponseLimitsToJson(
  WellKnownStarResponseLimits instance,
) => <String, dynamic>{
  'version': instance.version,
  'traitDefinitions': instance.traitDefinitions,
  'rules': instance.rules,
  'defaultsHash': instance.defaultsHash,
};
