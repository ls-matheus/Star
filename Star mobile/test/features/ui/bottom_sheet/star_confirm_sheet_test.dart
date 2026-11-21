import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/test_l10n.dart';

Widget _buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('StarConfirmSheet', () {
    testWidgets('tap confirm fires callback and resolves with true', (
      tester,
    ) async {
      var onConfirmCalls = 0;
      Future<bool?>? pendingResult;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                pendingResult = StarConfirmSheet.show(
                  context,
                  title: 'Delete Item',
                  description: 'Are you sure?',
                  confirmLabel: 'Delete',
                  isDanger: true,
                  onConfirm: () => onConfirmCalls++,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Cancel'), findsNothing);
      expect(find.byType(StarButton), findsOneWidget);

      await tester.tap(find.widgetWithText(StarButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(onConfirmCalls, 1);
      expect(await pendingResult, isTrue);
    });

    testWidgets('dismiss without confirming resolves with null', (
      tester,
    ) async {
      var onConfirmCalls = 0;
      Future<bool?>? pendingResult;
      late BuildContext capturedContext;

      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (context) {
              capturedContext = context;
              return ElevatedButton(
                onPressed: () {
                  pendingResult = StarConfirmSheet.show(
                    context,
                    title: 'Unpin message',
                    description: 'Are you sure?',
                    confirmLabel: 'Unpin',
                    onConfirm: () => onConfirmCalls++,
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Unpin message'), findsOneWidget);

      Navigator.of(capturedContext).pop();
      await tester.pumpAndSettle();

      expect(onConfirmCalls, 0);
      expect(await pendingResult, isNull);
    });

    testWidgets(
      'isDanger=true renders the dangerPrimary StarButton variant',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  unawaited(
                    StarConfirmSheet.show(
                      context,
                      title: 'Delete',
                      confirmLabel: 'Delete',
                      isDanger: true,
                      onConfirm: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        final dangerColor = _resolveButtonFill(tester);

        await tester.tap(find.byType(StarButton));
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          _buildTestApp(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  unawaited(
                    StarConfirmSheet.show(
                      context,
                      title: 'Confirm',
                      confirmLabel: 'OK',
                      onConfirm: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final primaryColor = _resolveButtonFill(tester);

        expect(
          dangerColor,
          isNot(equals(primaryColor)),
          reason:
              'danger variant must render a different fill color than primary',
        );
      },
    );
  });
}

Color? _resolveButtonFill(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.byType(StarButton),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  final decoration = container.decoration as BoxDecoration?;
  return decoration?.color;
}
