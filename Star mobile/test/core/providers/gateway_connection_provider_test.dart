import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_properties.dart';
import 'package:star_app/core/gateway/gateway_identify_client_properties.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/core/router/app_location_persistence.dart';
import 'package:star_dart/gateway.dart';

import '../../helpers/open_test_database.dart';

void main() {
  test('buildGatewayIdentifyProperties mirrors API user agent', () {
    const properties = StarClientProperties(
      schemaVersion: 1,
      clientPlatform: 'ios',
      clientRuntime: 'flutter',
      os: 'ios',
      browser: 'star',
      device: 'mobile',
      locale: 'en-US',
      systemLocale: 'en_US',
      userAgent: 'Star iOS/1.2.3 (beta)',
      clientVersion: '1.2.3',
      releaseChannel: 'beta',
      browserVersion: '1.2.3',
      buildNumber: 412,
      betaNumber: 14,
    );

    final GatewayIdentifyProperties gateway = buildGatewayIdentifyProperties(
      properties,
    );

    expect(gateway.userAgent, 'Star iOS/1.2.3 (beta)');
    expect(
      gateway.toJson(),
      containsPair('user_agent', 'Star iOS/1.2.3 (beta)'),
    );
    expect(gateway.toJson(), containsPair('browser', 'star'));
    expect(gateway.toJson(), containsPair('device', 'mobile'));
    expect(gateway.toJson(), containsPair('build_number', 412));
    expect(gateway.toJson(), containsPair('beta_number', 14));
    final Map<String, dynamic> wire = toClientPropertiesWireMap(properties);
    expect(wire, containsPair('build_number', 412));
    expect(wire, containsPair('beta_number', 14));
  });

  test('gateway identify properties serialises mobile', () {
    const properties = GatewayIdentifyProperties(
      os: 'ios',
      browser: 'star',
      device: 'mobile',
      mobile: true,
    );

    expect(properties.toJson(), containsPair('mobile', true));
  });

  test('restoreIdentifyInitialGuildId uses persisted guild path', () async {
    final db = openTestDatabase();
    persistAppLocation(db, '/channels/guild-99/chan-1');
    await Future<void>.delayed(Duration.zero);

    final ProviderContainer container = ProviderContainer(
      overrides: [starDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await restoreIdentifyInitialGuildId(
      container.read(identifyInitialGuildIdProvider.notifier),
      db,
    );
    expect(container.read(identifyInitialGuildIdProvider), 'guild-99');
  });

  test('restoreIdentifyInitialGuildId ignores @me paths', () async {
    final db = openTestDatabase();
    persistAppLocation(db, '/channels/@me/dm-1');
    await Future<void>.delayed(Duration.zero);

    final ProviderContainer container = ProviderContainer(
      overrides: [starDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await restoreIdentifyInitialGuildId(
      container.read(identifyInitialGuildIdProvider.notifier),
      db,
    );
    expect(container.read(identifyInitialGuildIdProvider), isNull);
  });
}
