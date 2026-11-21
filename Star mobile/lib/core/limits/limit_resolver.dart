import 'package:star_app/core/limits/limit_evaluator.dart';
import 'package:star_app/core/limits/limit_types.dart';
import 'package:star_app/core/limits/limit_wire_format.dart';
import 'package:star_dart/export.dart';

int resolveInstanceLimit({
  required WellKnownStarResponseLimits limits,
  required String key,
  required LimitMatchContext context,
  required int fallback,
}) {
  final LimitConfigSnapshot snapshot = expandLimitWireFormat(limits);
  final LimitEvaluator evaluator = LimitEvaluator(snapshot);
  final int resolved = evaluator.resolveOne(context, key);
  if (resolved < 0) {
    return fallback;
  }
  return resolved;
}
