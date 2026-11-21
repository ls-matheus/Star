import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/tabs/star_segmented_tabs.dart';
import 'package:star_app/features/ui/tabs/star_tabs.dart';
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
  const testTabs = [
    StarTab(label: 'General'),
    StarTab(label: 'Advanced'),
    StarTab(label: 'About'),
  ];

  group('StarTabs', () {
    testWidgets('renders all tab labels', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarTabs(tabs: testTabs, selectedIndex: 0, onChanged: (_) {}),
        ),
      );

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('calls onChanged with correct index when tapped', (
      tester,
    ) async {
      var tappedIndex = -1;
      await tester.pumpWidget(
        buildTestApp(
          StarTabs(
            tabs: testTabs,
            selectedIndex: 0,
            onChanged: (index) => tappedIndex = index,
          ),
        ),
      );

      await tester.tap(find.text('Advanced'));
      expect(tappedIndex, 1);

      await tester.tap(find.text('About'));
      expect(tappedIndex, 2);
    });

    testWidgets('renders icon when provided', (tester) async {
      final tabsWithIcon = [
        const StarTab(label: 'Home', icon: Icons.home),
        const StarTab(label: 'Settings'),
      ];

      await tester.pumpWidget(
        buildTestApp(
          StarTabs(tabs: tabsWithIcon, selectedIndex: 0, onChanged: (_) {}),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('supports vertical mobile layouts', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarTabs(
            tabs: const [
              StarTab(label: 'Home', icon: Icons.home),
              StarTab(label: 'Search', icon: Icons.search),
            ],
            selectedIndex: 0,
            direction: Axis.vertical,
            onChanged: (_) {},
          ),
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex).first);
      expect(flex.direction, Axis.vertical);
      expect(flex.crossAxisAlignment, CrossAxisAlignment.stretch);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  group('StarSegmentedTabs', () {
    testWidgets('renders all tab labels', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarSegmentedTabs(
            tabs: testTabs,
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('General'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('calls onChanged with correct index when tapped', (
      tester,
    ) async {
      var tappedIndex = -1;
      await tester.pumpWidget(
        buildTestApp(
          StarSegmentedTabs(
            tabs: testTabs,
            selectedIndex: 0,
            onChanged: (index) => tappedIndex = index,
          ),
        ),
      );

      await tester.tap(find.text('Advanced'));
      expect(tappedIndex, 1);
    });
  });
}
