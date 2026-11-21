import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/observability/star_observability.dart';
import 'package:star_app/core/talker.dart';
import 'package:talker/talker.dart';

void main() {
  setUp(talker.cleanHistory);
  tearDown(talker.cleanHistory);

  test('recordFlutterError logs the exception in Talker', () {
    final StateError error = StateError('widget build failed');
    final StackTrace stackTrace = StackTrace.current;

    StarObservability.instance.recordFlutterError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'widgets library',
        context: ErrorDescription('building TestWidget'),
      ),
    );

    expect(talker.history, hasLength(1));
    final TalkerData entry = talker.history.single;
    expect(entry, isA<TalkerError>());
    expect(entry.error, error);
    expect(entry.stackTrace, stackTrace);
    expect(entry.message, 'widgets library: building TestWidget');
  });

  test('recordError logs zone errors in Talker when measure is off', () {
    final Exception error = Exception('zone failure');
    final StackTrace stackTrace = StackTrace.current;

    StarObservability.instance.recordError(
      error,
      stackTrace: stackTrace,
      source: 'zone',
    );

    expect(talker.history, hasLength(1));
    final TalkerData entry = talker.history.single;
    expect(entry, isA<TalkerException>());
    expect(entry.exception, error);
    expect(entry.stackTrace, stackTrace);
    expect(entry.message, 'zone');
  });
}
