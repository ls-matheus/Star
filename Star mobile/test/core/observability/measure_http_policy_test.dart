import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/instance/instance_config_snapshot.dart';
import 'package:star_app/core/observability/measure_http_policy.dart';

void main() {
  const MeasureHttpPolicy policy = kMeasureHttpPolicy;

  final InstanceConfigSnapshot official =
      InstanceConfigSnapshot.officialDefault();
  const InstanceConfigSnapshot selfHosted = InstanceConfigSnapshot(
    apiBaseUrl: 'https://chat.example.org/api/v1',
    gatewayUrl: 'wss://gateway.chat.example.org',
    displayDomain: 'chat.example.org',
  );

  test('tracks only official instance API hosts', () {
    expect(
      policy.shouldTrackHttpRequest(
        instance: official,
        requestUri: Uri.parse('https://star.invalid/api/v1/users/@me'),
      ),
      isTrue,
    );
    expect(
      policy.shouldTrackHttpRequest(
        instance: selfHosted,
        requestUri: Uri.parse('https://chat.example.org/api/v1/users/@me'),
      ),
      isFalse,
    );
  });

  test('isOfficialStarInstance includes canary defaults', () {
    const InstanceConfigSnapshot canary = InstanceConfigSnapshot(
      apiBaseUrl: 'https://canary.star.invalid/api/v1',
      gatewayUrl: 'wss://gateway.canary.star.invalid',
      displayDomain: 'canary.star.invalid',
    );
    expect(policy.isOfficialStarInstance(canary), isTrue);
    expect(
      policy.shouldTrackHttpRequest(
        instance: canary,
        requestUri: Uri.parse('https://canary.star.invalid/api/v1/guilds'),
      ),
      isTrue,
    );
  });
}
