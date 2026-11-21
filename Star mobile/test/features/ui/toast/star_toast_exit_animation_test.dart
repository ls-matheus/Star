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
  group('StarToastOverlay exit animation', () {
    testWidgets('keeps toast visible while manual dismiss animates', (
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
              message: 'Animated dismiss',
              duration: Duration(seconds: 30),
            ),
          );

      await tester.pump();
      await tester.pump(starToastAnimationDuration);

      final List<ToastEntry> actualEntries = container.read(toastProvider);
      final int actualToastId = actualEntries.single.id;

      container.read(toastProvider.notifier).dismiss(actualToastId);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Animated dismiss'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Animated dismiss'), findsNothing);

      await tester.pump(const Duration(seconds: 30));
      await tester.pump();
    });

    testWidgets('keeps toast visible while auto dismiss animates', (
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
              message: 'Auto dismiss',
              duration: Duration(milliseconds: 50),
            ),
          );

      await tester.pump();
      expect(find.text('Auto dismiss'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Auto dismiss'), findsOneWidget);

      await tester.pump(starToastAnimationDuration);
      await tester.pump();

      expect(find.text('Auto dismiss'), findsNothing);
    });
  });
}
