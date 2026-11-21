// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'well_known_star_response_limits_rules.dart';

part 'well_known_star_response_limits.g.dart';

@JsonSerializable()
class WellKnownStarResponseLimits {
  const WellKnownStarResponseLimits({
    required this.version,
    required this.traitDefinitions,
    required this.rules,
    required this.defaultsHash,
  });

  factory WellKnownStarResponseLimits.fromJson(Map<String, Object?> json) =>
      _$WellKnownStarResponseLimitsFromJson(json);

  /// Wire format version
  @JsonKey(defaultValue: 0)
  final num version;

  /// Available trait definitions (e.g., "premium")
  @JsonKey(defaultValue: <String>[])
  final List<String> traitDefinitions;

  /// Array of limit rules to evaluate
  @JsonKey(defaultValue: <WellKnownStarResponseLimitsRules>[])
  final List<WellKnownStarResponseLimitsRules> rules;

  /// Hash of the default limit values for cache invalidation
  @JsonKey(defaultValue: '')
  final String defaultsHash;

  Map<String, Object?> toJson() => _$WellKnownStarResponseLimitsToJson(this);
}
