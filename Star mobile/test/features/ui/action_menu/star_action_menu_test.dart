import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/action_menu/star_action_menu.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

import '../../../helpers/input_modality_override.dart';
import '../../../helpers/wide_layout_test_sizes.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [inputModalityOverride(touch: false)],
    child: MaterialApp(
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

void useWideSurface(WidgetTester tester) {
  tester.view.physicalSize = kWideTestViewportSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void useMobileSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('StarActionMenu', () {
    testWidgets('shows menu items when StarActionMenu.show is called', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  StarActionMenu.show(
                    context,
                    position: const Offset(100, 100),
                    builder: (context, close) => [
                      StarMenuItem(label: 'Edit', onPressed: () {}),
                      const StarMenuDivider(),
                      StarMenuItem(
                        label: 'Delete',
                        onPressed: () {},
                        icon: PhosphorIconsBold.trash,
                        isDanger: true,
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Menu'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('wraps overlay items in Material at the given position', (
      tester,
    ) async {
      useWideSurface(tester);

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  StarActionMenu.show(
                    context,
                    position: const Offset(240, 180),
                    builder: (context, close) => [
                      StarMenuItem(label: 'Edit', onPressed: () {}),
                    ],
                  ),
                );
              },
              child: const Text('Open Menu'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      expect(
        find.ancestor(of: find.text('Edit'), matching: find.byType(Material)),
        findsWidgets,
      );

      final RenderParagraph paragraph = tester.renderObject(find.text('Edit'));
      expect(paragraph.text.style?.decoration, isNot(TextDecoration.underline));

      final Offset menuTopLeft = tester.getTopLeft(find.text('Edit'));
      expect(menuTopLeft.dx, closeTo(240, 48));
      expect(menuTopLeft.dy, closeTo(180, 48));
    });

    testWidgets('calls onPressed when menu item is tapped', (tester) async {
      var editPressed = false;

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  StarActionMenu.show(
                    context,
                    position: const Offset(100, 100),
                    builder: (context, close) => [
                      StarMenuItem(
                        label: 'Edit',
                        onPressed: () {
                          editPressed = true;
                          close();
                        },
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Menu'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editPressed, isTrue);
    });

    testWidgets('dismisses when tapping outside the menu', (tester) async {
      useWideSurface(tester);

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  StarActionMenu.show(
                    context,
                    position: const Offset(100, 100),
                    builder: (context, close) => [
                      StarMenuItem(label: 'Edit', onPressed: () {}),
                    ],
                  ),
                );
              },
              child: const Text('Open Menu'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);

      await tester.tapAt(const Offset(500, 500));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('mobile presentation groups items into titled sections', (
      tester,
    ) async {
      useMobileSurface(tester);

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                unawaited(
                  StarActionMenu.show(
                    context,
                    position: const Offset(100, 100),
                    builder: (context, close) => [
                      const StarMenuSectionHeader(label: 'Primary actions'),
                      StarMenuItem(
                        label: 'Edit',
                        hint: 'Quick action',
                        onPressed: () {},
                      ),
                      const StarMenuDivider(),
                      const StarMenuSectionHeader(label: 'Danger zone'),
                      StarMenuItem(
                        label: 'Delete',
                        onPressed: () {},
                        isDanger: true,
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open Menu'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Primary actions'), findsOneWidget);
      expect(find.text('Danger zone'), findsOneWidget);
      expect(find.text('Quick action'), findsOneWidget);
      expect(find.byType(StarMenuGroup), findsNWidgets(2));
    });

    testWidgets('mobile bottom sheet dismisses on swipe-down over the body', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      useMobileSurface(tester);

      try {
        await tester.pumpWidget(
          buildTestApp(
            Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  unawaited(
                    StarActionMenu.show(
                      context,
                      position: const Offset(100, 100),
                      builder: (context, close) => [
                        StarMenuItem(label: 'Edit', onPressed: () {}),
                        StarMenuItem(
                          label: 'Delete',
                          onPressed: () {},
                          isDanger: true,
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Menu'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Menu'));
        await tester.pumpAndSettle();
        expect(find.text('Edit'), findsOneWidget);

        await tester.fling(find.text('Edit'), const Offset(0, 400), 1500);
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
