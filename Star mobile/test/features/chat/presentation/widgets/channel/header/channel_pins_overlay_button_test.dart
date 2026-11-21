import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/data/channel_pins_repository.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_pins_content.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_pins_overlay_button.dart';
import 'package:star_app/features/chat/providers/channel/channel_details_providers.dart';
import 'package:star_app/features/chat/providers/channel/channel_pins_open_request_provider.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

import '../../../../../../helpers/input_modality_override.dart';
import '../../../../../../helpers/open_test_database.dart';
import '../../../../../../helpers/test_l10n.dart';

const String _channelId = 'c1';

class _EmptyPins extends ChannelPins {
  @override
  Future<ChannelPinsState> build(String channelId) async {
    return const ChannelPinsState(
      items: <PinnedMessageEntry>[],
      hasMore: false,
    );
  }
}

void main() {
  testWidgets('open request shows the desktop pins overlay', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final ProviderContainer container = ProviderContainer(
      overrides: [
        starDatabaseProvider.overrideWithValue(openTestDatabase()),
        starClientProvider.overrideWithValue(
          StarClient(Dio(BaseOptions(baseUrl: 'https://api.star.invalid/v1'))),
        ),
        channelPinsProvider(_channelId).overrideWith(_EmptyPins.new),
        inputModalityOverride(touch: false),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _buildApp(
          buildChannelPinsButton(
            channelId: _channelId,
            guildId: 'g1',
            hasUnreadPins: false,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ChannelPinsContent), findsNothing);

    container.read(channelPinsOpenRequestProvider.notifier).open();
    await tester.pump();
    expect(find.byType(ChannelPinsContent), findsOneWidget);

    container.read(channelPinsOpenRequestProvider.notifier).open();
    await tester.pump();
    expect(find.byType(ChannelPinsContent), findsOneWidget);
  });
}

Widget _buildApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(
      body: Align(alignment: Alignment.topRight, child: child),
    ),
  );
}
