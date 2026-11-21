import 'package:test/test.dart';
import 'package:star_dart/gateway.dart';

void main() {
  test('GatewayIdentifyProperties includes user_agent in identify json', () {
    const properties = GatewayIdentifyProperties(
      os: 'android',
      browser: 'star',
      device: 'mobile',
      userAgent: 'Star Android/2.0.0 (stable)',
    );

    expect(properties.toJson()['user_agent'], 'Star Android/2.0.0 (stable)');
  });
}
