import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/observability/observability_reporting_provider.dart';

String _source(String path) => File(path).readAsStringSync();

void main() {
  const String nativeKey = 'flutter.$kObservabilityReportingEnabledKey';

  test('iOS starts Measure at launch only from the saved switch', () {
    final String appDelegate = _source('ios/Runner/AppDelegate.swift');

    expect(appDelegate, contains('"$nativeKey"'));
    expect(appDelegate, contains('BaseMeasureConfig(autoStart: false)'));
    expect(
      RegExp(r'Measure\.initialize\(').allMatches(appDelegate),
      hasLength(1),
    );
    expect(appDelegate, contains('"star_app/measure_reporting"'));
  });

  test('native code reports handled errors through StarNativeMeasure', () {
    final String androidMeasure = _source(
      'android/app/src/main/kotlin/com/star/StarNativeMeasure.kt',
    );
    final String androidRedaction = _source(
      'android/app/src/main/kotlin/com/star/MeasureLogRedaction.kt',
    );
    final String iosMeasure = _source('ios/Runner/StarNativeMeasure.swift');
    final String iosRedaction = _source('ios/Runner/MeasureLogRedaction.swift');

    expect(androidMeasure, contains('Measure.trackHandledException'));
    expect(androidMeasure, contains('redactThrowableForMeasure'));
    expect(androidMeasure, contains('"exception.source"'));
    expect(androidRedaction, contains('fun scrubForMeasure'));
    expect(iosMeasure, contains('Measure.trackError'));
    expect(iosMeasure, contains('MeasureLogRedaction.redactErrorForMeasure'));
    expect(iosMeasure, contains('"exception.source"'));
    expect(iosRedaction, contains('func scrubForMeasure'));
  });

  test('Android starts Measure at launch only from the saved switch', () {
    final String reporting = _source(
      'android/app/src/main/kotlin/com/star/MeasureReporting.kt',
    );
    final String application = _source(
      'android/app/src/main/kotlin/com/star/StarApplication.kt',
    );

    expect(reporting, contains('"$nativeKey"'));
    expect(reporting, contains('"FlutterSharedPreferences"'));
    expect(reporting, contains('MeasureConfig(autoStart = false)'));
    expect(reporting, contains('"star_app/measure_reporting"'));
    expect(application, isNot(contains('Measure.init')));
    expect(application, contains('MeasureReporting.startIfEnabled(this)'));
  });

  test('iOS does not enable native URLSession HTTP capture', () {
    final String appDelegate = _source('ios/Runner/AppDelegate.swift');

    expect(appDelegate, isNot(contains('MSRNetworkInterceptor.enable')));
  });
}
