import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/app_lock/presentation/app_lock_pin_input.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/test_l10n.dart';

Future<void> _pumpInput(
  WidgetTester tester, {
  required ValueChanged<String> onCompleted,
}) async {
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(
        body: AppLockPinInput(label: 'PIN', onCompleted: onCompleted),
      ),
    ),
  );
}

void main() {
  group('AppLockPinInput', () {
    testWidgets('renders one box per digit', (tester) async {
      await _pumpInput(tester, onCompleted: (_) {});

      expect(find.byType(AnimatedContainer), findsNWidgets(6));
    });

    testWidgets('reports the PIN once six digits are entered and clears it', (
      tester,
    ) async {
      String? completed;
      await _pumpInput(tester, onCompleted: (pin) => completed = pin);

      await tester.enterText(find.byType(TextField), '12345');
      await tester.pump();
      expect(completed, isNull);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();

      expect(completed, '123456');
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });
  });
}
