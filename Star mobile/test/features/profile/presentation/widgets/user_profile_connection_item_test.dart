import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/instance/instance_runtime_config.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_connection_item.dart';
import 'package:star_app/features/ui/icons/star_connection_icon.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_dart/export.dart';

import '../../../../helpers/test_l10n.dart';

const InstanceRuntimeConfig _config = InstanceRuntimeConfig(
  productName: 'Star',
  selfHosted: true,
  stripeEnabled: false,
  emailsEnabled: false,
  voiceEnabled: false,
  presignedAttachmentUploads: false,
  gifEnabled: false,
  blueskyEnabled: true,
  gifAttributionRequired: false,
  singleCommunity: false,
  directMessagesDisabled: false,
  registrationClosed: false,
  adminRegistrationUrlsEnabled: false,
  collectDateOfBirth: false,
  connectionProviders: <InstanceConnectionProviderSchema>[
    InstanceConnectionProviderSchema(id: 'sso', name: 'SSO', iconUrl: null),
  ],
);

Widget _app(List<ConnectionResponse> connections, double textScale) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [instanceRuntimeConfigProvider.overrideWithValue(_config)],
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: <Widget>[
            for (final ConnectionResponse connection in connections)
              UserProfileConnectionItem(connection: connection),
          ],
        ),
      ),
    ),
  );
}

ConnectionResponse _connection(
  ConnectionType type,
  String id, {
  String? providerId,
}) => ConnectionResponse(
  providerId: providerId,
  url: null,
  id: id,
  type: type,
  name: 'mystie.dev',
  verified: true,
  visibilityFlags: 0,
  sortOrder: 0,
);

void main() {
  for (final double scale in <double>[1, 1.3]) {
    testWidgets('connection icons share one square tile at text scale $scale', (
      tester,
    ) async {
      final List<ConnectionResponse> connections = <ConnectionResponse>[
        for (final ConnectionType type in ConnectionType.values)
          _connection(type, type.name),
      ];
      await tester.pumpWidget(_app(connections, scale));
      await tester.pumpAndSettle();
      final Finder name = find.text('mystie.dev');
      final List<Rect> names = <Rect>[
        for (int i = 0; i < name.evaluate().length; i++)
          tester.getRect(name.at(i)),
      ];
      expect(names, hasLength(connections.length));
      for (final Rect rect in names) {
        expect(rect.left, names.first.left);
      }
      final Finder tiles = find.byType(StarConnectionIconTile);
      expect(tiles, findsNWidgets(connections.length));
      for (int i = 0; i < connections.length; i++) {
        expect(
          tester.getSize(tiles.at(i)),
          const Size.square(StarConnectionIconTile.size),
        );
        final Rect tile = tester.getRect(tiles.at(i));
        final Rect glyph = tester.getRect(
          find.byType(StarConnectionIcon).at(i),
        );
        expect(glyph.center, tile.center);
      }
    });
  }

  testWidgets('oauth connections without a url are not links', (tester) async {
    await tester.pumpWidget(
      _app(<ConnectionResponse>[_connection(ConnectionType.oauth, 'oauth')], 1),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(PhosphorIconsBold.arrowSquareOut), findsNothing);
    expect(find.byIcon(PhosphorIconsBold.linkBreak), findsOneWidget);
  });

  testWidgets('oauth connections show their instance provider', (tester) async {
    await tester.pumpWidget(
      _app(<ConnectionResponse>[
        _connection(ConnectionType.oauth, 'oauth', providerId: 'sso'),
      ], 1),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(PhosphorIconsBold.plugsConnected), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.linkBreak), findsNothing);
  });

  testWidgets('domain connections stay links without a url', (tester) async {
    await tester.pumpWidget(
      _app(<ConnectionResponse>[
        _connection(ConnectionType.domain, 'domain'),
      ], 1),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(PhosphorIconsBold.arrowSquareOut), findsOneWidget);
  });
}
