import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_voice/star_voice.dart';
import 'package:star_voice/src/process_activity.g.dart';

class _RecordingProcessActivityApi extends VoiceProcessActivityHostApi {
  final List<String> calls = <String>[];

  @override
  Future<void> begin() async => calls.add('begin');

  @override
  Future<void> end() async => calls.add('end');
}

void main() {
  late _RecordingProcessActivityApi api;

  setUp(() {
    api = _RecordingProcessActivityApi();
    StarVoiceProcessActivity.instance.debugOverridePlatform(api: api);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('macOS begins and ends the activity once per transition', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final StarVoiceProcessActivity activity =
        StarVoiceProcessActivity.instance;

    await activity.setActive(active: true);
    await activity.setActive(active: true);
    await activity.setActive(active: false);
    await activity.setActive(active: false);

    expect(api.calls, <String>['begin', 'end']);
  });

  test('other platforms never reach the native api', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await StarVoiceProcessActivity.instance.setActive(active: true);

    expect(api.calls, isEmpty);
  });
}
