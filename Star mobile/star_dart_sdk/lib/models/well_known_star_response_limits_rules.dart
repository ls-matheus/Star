// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'well_known_star_response_limits_rules_filters.dart';

part 'well_known_star_response_limits_rules.g.dart';

@JsonSerializable()
class WellKnownStarResponseLimitsRules {
  const WellKnownStarResponseLimitsRules({
    required this.id,
    required this.overrides,
    this.filters,
  });

  factory WellKnownStarResponseLimitsRules.fromJson(
    Map<String, Object?> json,
  ) => _$WellKnownStarResponseLimitsRulesFromJson(json);

  /// Unique identifier for this limit rule
  @JsonKey(defaultValue: '')
  final String id;

  /// Filters that determine when this rule applies
  @JsonKey(includeIfNull: false)
  final WellKnownStarResponseLimitsRulesFilters? filters;

  /// Map of limit keys to their override values (differences from defaults)
  @JsonKey(defaultValue: <String, num>{})
  final Map<String, num> overrides;

  Map<String, Object?> toJson() =>
      _$WellKnownStarResponseLimitsRulesToJson(this);
}
