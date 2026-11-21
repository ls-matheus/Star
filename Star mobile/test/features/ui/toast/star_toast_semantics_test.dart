import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/star_toast_overlay.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/test_l10n.dart';

Widget buildToastTestApp(Widget child) {
  final StarColorTheme colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: StarToastOverlay(child: child)),
    ),
  );
}

void main() {
  group('StarToastOverlay semantics', () {
    testWidgets('toast exposes live region with message label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildToastTestApp(const SizedBox.shrink()));

      final ProviderContainer container = ProviderScope.containerOf(
        tester.element(find.byType(StarToastOverlay)),
      );
      container
          .read(toastProvider.notifier)
          .show(
            const StarToast(
              message: 'Settings saved',
              duration: Duration(seconds: 30),
            ),
          );

      await tester.pump();
      await tester.pump(starToastAnimationDuration);

      expect(find.bySemanticsLabel('Settings saved'), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Settings saved'),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
    });
  });
}
