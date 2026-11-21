import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/popout/star_popout.dart';
import 'package:star_app/material_ui.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('StarPopout', () {
    testWidgets('content is not visible initially', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarPopout(
            anchorBuilder: (context, toggle) =>
                TextButton(onPressed: toggle, child: const Text('Anchor')),
            contentBuilder: (context, close) => const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Popout Content'),
            ),
          ),
        ),
      );

      expect(find.text('Anchor'), findsOneWidget);
      expect(find.text('Popout Content'), findsNothing);
    });

    testWidgets('shows content when anchor is tapped', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarPopout(
            anchorBuilder: (context, toggle) =>
                TextButton(onPressed: toggle, child: const Text('Anchor')),
            contentBuilder: (context, close) => const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Popout Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();

      expect(find.text('Popout Content'), findsOneWidget);
    });

    testWidgets('dismiss barrier closes the popout', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarPopout(
            anchorBuilder: (context, toggle) =>
                TextButton(onPressed: toggle, child: const Text('Anchor')),
            contentBuilder: (context, close) => const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Popout Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();
      expect(find.text('Popout Content'), findsOneWidget);

      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(find.text('Popout Content'), findsNothing);
    });

    testWidgets('close callback hides content', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarPopout(
            anchorBuilder: (context, toggle) =>
                TextButton(onPressed: toggle, child: const Text('Anchor')),
            contentBuilder: (context, close) =>
                TextButton(onPressed: close, child: const Text('Close Me')),
          ),
        ),
      );

      await tester.tap(find.text('Anchor'));
      await tester.pumpAndSettle();
      expect(find.text('Close Me'), findsOneWidget);

      await tester.tap(find.text('Close Me'));
      await tester.pumpAndSettle();
      expect(find.text('Close Me'), findsNothing);
    });
  });
}
