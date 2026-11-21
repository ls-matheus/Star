import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_connection_confirm_modal.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

Widget buildTestApp({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required Widget child,
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      navigatorKey: rootNavigatorKey,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: child,
    ),
  );
}

Future<Completer<VoiceConnectionConfirmResult?>> pumpNestedNavModalOpener(
  WidgetTester tester, {
  required int otherDeviceCount,
}) async {
  final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> branchNavigatorKey =
      GlobalKey<NavigatorState>();
  final Completer<VoiceConnectionConfirmResult?> resultCompleter =
      Completer<VoiceConnectionConfirmResult?>();

  await tester.pumpWidget(
    buildTestApp(
      rootNavigatorKey: rootNavigatorKey,
      child: Navigator(
        key: branchNavigatorKey,
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<void>(
            builder: (BuildContext branchContext) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      unawaited(
                        showVoiceConnectionConfirmModal(
                          branchContext,
                          otherDeviceCount: otherDeviceCount,
                        ).then(resultCompleter.complete),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );

  return resultCompleter;
}

void main() {
  group('showVoiceConnectionConfirmModal', () {
    testWidgets('shows title and singular description', (tester) async {
      final Completer<VoiceConnectionConfirmResult?> resultCompleter =
          await pumpNestedNavModalOpener(tester, otherDeviceCount: 1);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Voice connection confirmation'), findsOneWidget);
      expect(find.textContaining('1 other device'), findsOneWidget);

      await tester.tap(find.text("Do nothing, I don't want to join"));
      await tester.pumpAndSettle();

      expect(await resultCompleter.future, isNull);
    });

    testWidgets('switch button returns switchToThisDevice and closes modal', (
      tester,
    ) async {
      final Completer<VoiceConnectionConfirmResult?> resultCompleter =
          await pumpNestedNavModalOpener(tester, otherDeviceCount: 1);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Switch to this device'));
      await tester.pumpAndSettle();

      expect(
        await resultCompleter.future,
        VoiceConnectionConfirmResult.switchToThisDevice,
      );
      expect(find.text('Voice connection confirmation'), findsNothing);
    });

    testWidgets('just join button returns justJoin and closes modal', (
      tester,
    ) async {
      final Completer<VoiceConnectionConfirmResult?> resultCompleter =
          await pumpNestedNavModalOpener(tester, otherDeviceCount: 1);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Just join (keep other connections)'));
      await tester.pumpAndSettle();

      expect(
        await resultCompleter.future,
        VoiceConnectionConfirmResult.justJoin,
      );
      expect(find.text('Voice connection confirmation'), findsNothing);
    });

    testWidgets('cancel button returns null and closes modal', (tester) async {
      final Completer<VoiceConnectionConfirmResult?> resultCompleter =
          await pumpNestedNavModalOpener(tester, otherDeviceCount: 1);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Do nothing, I don't want to join"));
      await tester.pumpAndSettle();

      expect(await resultCompleter.future, isNull);
      expect(find.text('Voice connection confirmation'), findsNothing);
    });

    testWidgets('header close button returns null and closes modal', (
      tester,
    ) async {
      final Completer<VoiceConnectionConfirmResult?> resultCompleter =
          await pumpNestedNavModalOpener(tester, otherDeviceCount: 1);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(PhosphorIconsBold.x));
      await tester.pumpAndSettle();

      expect(await resultCompleter.future, isNull);
      expect(find.text('Voice connection confirmation'), findsNothing);
    });
  });
}
