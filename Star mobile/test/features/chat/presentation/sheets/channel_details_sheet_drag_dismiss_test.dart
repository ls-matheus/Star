import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/chat/presentation/sheets/channel_details_sheet.dart';
import 'package:star_app/features/members/providers/member_list_subscription_provider.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../helpers/open_test_database.dart';
import '../../../../helpers/test_l10n.dart';

const String _guildId = 'guild_1';
const String _channelId = 'chan_1';
const Channel _channel = Channel(
  id: _channelId,
  guildId: _guildId,
  name: 'general',
);

class _FakeAppearance extends AppearancePreferences {
  @override
  AppearancePreferencesState build() =>
      const AppearancePreferencesState(showFavorites: false);
}

ProviderContainer _container(StarDatabase database) {
  return ProviderContainer(
    overrides: <Override>[
      starDatabaseProvider.overrideWithValue(database),
      appearancePreferencesProvider.overrideWith(_FakeAppearance.new),
      memberListDetailsSubscriptionProvider(
        _guildId,
        _channelId,
        true,
      ).overrideWith((ref) {}),
    ],
  );
}

Widget _host(ProviderContainer container, {required Widget child}) {
  final colorTheme = buildDarkColorTheme();
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

Future<void> _openSheet(
  WidgetTester tester,
  ProviderContainer container,
  Future<void> Function(BuildContext context) show,
) async {
  await tester.pumpWidget(
    _host(
      container,
      child: Builder(
        builder: (BuildContext context) => ElevatedButton(
          onPressed: () => show(context),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Finder get _handle => find.byType(StarBottomSheetDragHandle);

void main() {
  testWidgets('member list drawer closes when dragged below the half snap', (
    tester,
  ) async {
    final StarDatabase database = openTestDatabase();
    final ProviderContainer container = _container(database);
    addTearDown(container.dispose);

    await _openSheet(
      tester,
      container,
      (context) =>
          showChannelDetailsSheet(context, channel: _channel, dm: null),
    );
    expect(_handle, findsOneWidget);

    await tester.drag(_handle, const Offset(0, 440));
    await tester.pumpAndSettle();

    expect(_handle, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member list drawer closes on a downward fling', (tester) async {
    final StarDatabase database = openTestDatabase();
    final ProviderContainer container = _container(database);
    addTearDown(container.dispose);

    await _openSheet(
      tester,
      container,
      (context) =>
          showChannelDetailsSheet(context, channel: _channel, dm: null),
    );

    final RenderBox sheetBox = tester.renderObject(
      find.byType(StarDraggableScrollableSheet),
    );
    await tester.drag(
      _handle,
      Offset(0, sheetBox.constraints.maxHeight * 0.35),
    );
    await tester.pumpAndSettle();
    expect(_handle, findsOneWidget);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(_handle),
    );
    Duration elapsed = Duration.zero;
    for (int i = 0; i < 10; i += 1) {
      elapsed += const Duration(milliseconds: 4);
      await gesture.moveBy(const Offset(0, 4.5), timeStamp: elapsed);
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_handle, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a partial pill drag springs the sheet back to its rest size', (
    tester,
  ) async {
    final StarDatabase database = openTestDatabase();
    final ProviderContainer container = _container(database);
    addTearDown(container.dispose);

    await _openSheet(
      tester,
      container,
      (context) =>
          showChannelDetailsSheet(context, channel: _channel, dm: null),
    );

    final double restTop = tester.getTopLeft(_handle).dy;

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(_handle),
    );
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(
      tester.getTopLeft(_handle).dy,
      greaterThan(restTop),
      reason: 'the sheet must follow the finger',
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(_handle, findsOneWidget, reason: '30px is below the threshold');
    expect(tester.getTopLeft(_handle).dy, closeTo(restTop, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('identity header drag resizes the sheet', (tester) async {
    final StarDatabase database = openTestDatabase();
    final ProviderContainer container = _container(database);
    addTearDown(container.dispose);

    await _openSheet(
      tester,
      container,
      (context) =>
          showChannelDetailsSheet(context, channel: _channel, dm: null),
    );

    final Finder title = find.text('general');
    expect(title, findsOneWidget);
    final double restTop = tester.getTopLeft(_handle).dy;

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(title),
    );
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(tester.getTopLeft(_handle).dy, greaterThan(restTop));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(_handle, findsOneWidget);
    expect(tester.getTopLeft(_handle).dy, closeTo(restTop, 0.5));
    expect(tester.takeException(), isNull);
  });
}
