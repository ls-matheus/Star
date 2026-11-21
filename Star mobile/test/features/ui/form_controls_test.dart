import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/checkbox/star_checkbox.dart';
import 'package:star_app/features/ui/radio_group/star_radio_group.dart';
import 'package:star_app/features/ui/toggle_switch/star_switch_control.dart';
import 'package:star_app/features/ui/toggle_switch/star_toggle_switch.dart';
import 'package:star_app/material_ui.dart';

import '../../helpers/test_l10n.dart';

Widget buildTestApp(Widget child) {
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
    home: Scaffold(body: child),
  );
}

void main() {
  group('StarCheckbox', () {
    testWidgets('renders label and toggles on tap', (tester) async {
      var checked = false;
      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return StarCheckbox(
                value: checked,
                onChanged: (v) => setState(() => checked = v ?? false),
                label: 'Accept terms',
              );
            },
          ),
        ),
      );

      expect(find.text('Accept terms'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.text('Accept terms'));
      await tester.pump();
      expect(checked, isTrue);
    });

    testWidgets('does not toggle when disabled', (tester) async {
      var checked = false;
      await tester.pumpWidget(
        buildTestApp(
          StarCheckbox(
            value: checked,
            onChanged: (v) => checked = v ?? false,
            label: 'Disabled',
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pump();
      expect(checked, isFalse);
    });
  });

  group('StarRadioGroup', () {
    testWidgets('renders all items and selects on tap', (tester) async {
      var selected = 'a';
      final items = [
        const StarRadioItem(value: 'a', label: 'Alpha'),
        const StarRadioItem(value: 'b', label: 'Beta'),
        const StarRadioItem(value: 'c', label: 'Gamma'),
      ];

      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return StarRadioGroup<String>(
                value: selected,
                items: items,
                onChanged: (v) => setState(() => selected = v),
              );
            },
          ),
        ),
      );

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(3));

      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(selected, 'b');
    });

    testWidgets('supports horizontal direction', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarRadioGroup<int>(
            value: 1,
            items: const [
              StarRadioItem(value: 1, label: 'One'),
              StarRadioItem(value: 2, label: 'Two'),
            ],
            onChanged: (_) {},
            direction: Axis.horizontal,
          ),
        ),
      );

      final flex = tester.widget<Flex>(find.byType(Flex));
      expect(flex.direction, Axis.horizontal);
    });
  });

  group('StarToggleSwitch', () {
    testWidgets('renders label and toggles on tap', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        buildTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              return StarToggleSwitch(
                value: toggled,
                onChanged: (v) => setState(() => toggled = v),
                label: 'Enable notifications',
              );
            },
          ),
        ),
      );

      expect(find.text('Enable notifications'), findsOneWidget);
      expect(find.byType(StarSwitchControl), findsOneWidget);

      await tester.tap(find.text('Enable notifications'));
      await tester.pump();
      expect(toggled, isTrue);
    });

    testWidgets('does not toggle when disabled', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        buildTestApp(
          StarToggleSwitch(
            value: toggled,
            onChanged: (v) => toggled = v,
            label: 'Disabled switch',
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.text('Disabled switch'));
      await tester.pump();
      expect(toggled, isFalse);
    });

    testWidgets(
      'renders description and icon for stacked mobile settings rows',
      (tester) async {
        var toggled = false;

        await tester.pumpWidget(
          buildTestApp(
            StatefulBuilder(
              builder: (context, setState) {
                return StarToggleSwitch(
                  value: toggled,
                  onChanged: (value) => setState(() => toggled = value),
                  label: 'Enable notifications',
                  description: 'Alerts for mentions, replies, and invites.',
                  icon: Icons.notifications_outlined,
                );
              },
            ),
          ),
        );

        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
        expect(
          find.text('Alerts for mentions, replies, and invites.'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('Alerts for mentions, replies, and invites.'),
        );
        await tester.pump();

        expect(toggled, isTrue);
      },
    );
  });

  group('semantics', () {
    testWidgets('checkbox exposes checked state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarCheckbox(value: true, onChanged: (_) {}, label: 'Accept terms'),
        ),
      );

      expect(find.bySemanticsLabel('Accept terms'), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Accept terms'),
      );
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
    });

    testWidgets('radio group exposes selected option', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarRadioGroup<String>(
            value: 'b',
            items: const [
              StarRadioItem(value: 'a', label: 'Alpha'),
              StarRadioItem(value: 'b', label: 'Beta'),
            ],
            onChanged: (_) {},
          ),
        ),
      );

      final SemanticsNode beta = tester.getSemantics(find.text('Beta'));
      expect(beta.flagsCollection.isChecked, CheckedState.isTrue);
      expect(beta.flagsCollection.isSelected, Tristate.isTrue);
    });

    testWidgets('toggle switch exposes toggled state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarToggleSwitch(
            value: true,
            onChanged: (_) {},
            label: 'Enable notifications',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Enable notifications'), findsOneWidget);
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Enable notifications'),
      );
      expect(node.flagsCollection.isToggled, isNot(Tristate.none));
      expect(node.flagsCollection.isToggled, Tristate.isTrue);
    });
  });
}
