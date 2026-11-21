import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/button/star_button_variant.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

import '../../../helpers/test_l10n.dart';

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

Color? buttonBorderColor(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  final decoration = container.decoration! as BoxDecoration;
  return decoration.border?.top.color;
}

Future<void> hoverButton(WidgetTester tester) async {
  final center = tester.getCenter(find.byType(StarButton));
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: center);
  await tester.pumpAndSettle();
}

void main() {
  group('StarButton', () {
    testWidgets('primary variant renders label text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(StarButton.primary(onPressed: () {}, label: 'Click me')),
      );

      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          StarButton.primary(onPressed: () => tapped = true, label: 'Tap'),
        ),
      );

      await tester.tap(find.text('Tap'));
      expect(tapped, isTrue);
    });

    testWidgets('does NOT call onPressed when loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          StarButton.primary(
            onPressed: () => tapped = true,
            label: 'Loading',
            isLoading: true,
          ),
        ),
      );

      await tester.tap(find.byType(StarButton));
      expect(tapped, isFalse);
    });

    testWidgets('shows StarLoadingSpinner when loading', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarButton.primary(
            onPressed: () {},
            label: 'Loading',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(StarLoadingSpinner), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('all 7 named constructors create a widget', (tester) async {
      final constructors = <Widget>[
        StarButton.primary(onPressed: () {}, label: 'primary'),
        StarButton.secondary(onPressed: () {}, label: 'secondary'),
        StarButton.dangerPrimary(onPressed: () {}, label: 'dangerPrimary'),
        StarButton.dangerSecondary(
          onPressed: () {},
          label: 'dangerSecondary',
        ),
        StarButton.inverted(onPressed: () {}, label: 'inverted'),
        StarButton.invertedOutline(
          onPressed: () {},
          label: 'invertedOutline',
        ),
        StarButton.ghost(onPressed: () {}, label: 'ghost'),
      ];

      for (final button in constructors) {
        await tester.pumpWidget(buildTestApp(button));
        expect(find.byType(StarButton), findsOneWidget);
      }
    });

    testWidgets('compact size renders with height 32', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarButton.primary(
            onPressed: () {},
            label: 'Compact',
            size: StarButtonSize.compact,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final constraints = container.constraints!;
      expect(constraints.minHeight, 32);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarButton.primary(
            onPressed: () {},
            label: 'With icon',
            icon: PhosphorIconsBold.check,
          ),
        ),
      );

      expect(find.byType(PhosphorIcon), findsOneWidget);
      expect(find.text('With icon'), findsOneWidget);
    });

    testWidgets('renders as square icon-only button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarButton.primary(
            onPressed: () {},
            icon: PhosphorIconsBold.plus,
            isSquare: true,
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final constraints = container.constraints!;
      expect(constraints.minWidth, constraints.minHeight);
    });

    testWidgets('icon-only button is findable with semanticLabel', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          StarButton.circle(
            onPressed: () {},
            icon: PhosphorIconsBold.plus,
            semanticLabel: 'Add item',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Add item'), findsOneWidget);
    });

    testWidgets('loading button announces loading state', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          StarButton.primary(
            onPressed: () {},
            label: 'Submit',
            isLoading: true,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Submit, Loading'), findsOneWidget);
    });

    group('accent borders', () {
      late StarColorTheme colors;

      setUp(() {
        colors = buildDarkColorTheme();
      });

      testWidgets('primary uses brand-mixed border color', (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            StarButton.primary(onPressed: () {}, label: 'Primary'),
          ),
        );

        expect(
          buttonBorderColor(tester),
          StarButtonVariant.primary.borderColor(colors),
        );
      });

      testWidgets('primary hover updates border color', (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            StarButton.primary(onPressed: () {}, label: 'Primary'),
          ),
        );

        await hoverButton(tester);

        expect(
          buttonBorderColor(tester),
          StarButtonVariant.primary.borderColor(colors, hovered: true),
        );
      });

      testWidgets('secondary uses accent border color', (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            StarButton.secondary(onPressed: () {}, label: 'Secondary'),
          ),
        );

        expect(
          buttonBorderColor(tester),
          StarButtonVariant.secondary.borderColor(colors),
        );
      });

      testWidgets('secondary hover updates border color', (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            StarButton.secondary(onPressed: () {}, label: 'Secondary'),
          ),
        );

        await hoverButton(tester);

        expect(
          buttonBorderColor(tester),
          StarButtonVariant.secondary.borderColor(colors, hovered: true),
        );
      });

      testWidgets('dangerSecondary uses accent border color', (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            StarButton.dangerSecondary(
              onPressed: () {},
              label: 'Danger secondary',
            ),
          ),
        );

        expect(
          buttonBorderColor(tester),
          StarButtonVariant.dangerSecondary.borderColor(colors),
        );
      });

      testWidgets('dangerSecondary hover updates border color', (tester) async {
        await tester.pumpWidget(
          buildTestApp(
            StarButton.dangerSecondary(
              onPressed: () {},
              label: 'Danger secondary',
            ),
          ),
        );

        await hoverButton(tester);

        expect(
          buttonBorderColor(tester),
          StarButtonVariant.dangerSecondary.borderColor(
            colors,
            hovered: true,
          ),
        );
      });
    });
  });
}
