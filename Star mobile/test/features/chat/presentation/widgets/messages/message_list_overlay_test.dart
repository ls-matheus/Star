import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_list_overlay.dart';
import 'package:star_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../helpers/test_l10n.dart';

void _noop() {}

Widget _overlay({required bool showUnreadBar}) {
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
      body: MessageListOverlay(
        body: const SizedBox.expand(),
        showUnreadBar: showUnreadBar,
        unreadCount: 3,
        isEstimated: false,
        unreadSince: null,
        onJumpToUnread: _noop,
        onMarkRead: _noop,
        showLoadErrorBar: false,
        loadErrorRetryInFlight: false,
        onRetryLoadMessages: _noop,
        scaleRatio: 1,
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, {required bool showUnreadBar}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [use12HourTimeFormatProvider.overrideWithValue(false)],
      child: _overlay(showUnreadBar: showUnreadBar),
    ),
  );
}

double _barOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(MessageListNewMessagesBar),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

void main() {
  testWidgets('unread bar fades in and out instead of cutting', (tester) async {
    await _pump(tester, showUnreadBar: false);
    expect(find.byType(MessageListNewMessagesBar), findsNothing);

    await _pump(tester, showUnreadBar: true);
    await tester.pump(StarMotionTheme.normalDuration ~/ 2);
    expect(_barOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_barOpacity(tester), 1);

    await _pump(tester, showUnreadBar: false);
    await tester.pump(StarMotionTheme.normalDuration ~/ 2);
    expect(find.byType(MessageListNewMessagesBar), findsOneWidget);
    expect(_barOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(find.byType(MessageListNewMessagesBar), findsNothing);
  });
}
