// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'well_known_star_response_limits_rules_filters.g.dart';

@JsonSerializable()
class WellKnownStarResponseLimitsRulesFilters {
  const WellKnownStarResponseLimitsRulesFilters({
    this.traits,
    this.guildFeatures,
  });

  factory WellKnownStarResponseLimitsRulesFilters.fromJson(
    Map<String, Object?> json,
  ) => _$WellKnownStarResponseLimitsRulesFiltersFromJson(json);

  /// Trait filters for this limit rule
  @JsonKey(includeIfNull: false)
  final List<String>? traits;

  /// Guild feature filters for this limit rule
  @JsonKey(includeIfNull: false)
  final List<String>? guildFeatures;

  Map<String, Object?> toJson() =>
      _$WellKnownStarResponseLimitsRulesFiltersToJson(this);
}
