import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/shell/presentation/mobile_main_tab_shell.dart';
import 'package:star_app/material_ui.dart';

void main() {
  testWidgets(
    'main tab shell updates bottom nav when the selected tab changes',
    (tester) async {
      var currentIndex = 1;
      final colorTheme = buildDarkColorTheme();

      Future<void> pumpShell() {
        return tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildStarTheme(
                colorTheme: colorTheme,
                textTheme: StarTextTheme.fromColors(colorTheme),
                layoutTheme: StarLayoutTheme.scaled(),
              ),
              home: MobileMainTabShell(
                navigationShell: Text('branch-$currentIndex'),
                bottomNav: Text('nav-$currentIndex'),
              ),
            ),
          ),
        );
      }

      await pumpShell();
      await tester.pumpAndSettle();

      expect(find.text('branch-1'), findsOneWidget);
      expect(find.text('nav-1'), findsOneWidget);

      currentIndex = 2;
      await pumpShell();
      await tester.pumpAndSettle();

      expect(find.text('branch-2'), findsOneWidget);
      expect(find.text('nav-2'), findsOneWidget);
      expect(find.text('nav-1'), findsNothing);
    },
  );
}
