import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/bottom_sheet/star_sheet_motion.dart';
import 'package:star_app/features/ui/page_sheet/star_page_sheet.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/test_l10n.dart';

const ValueKey<String> _shellKey = ValueKey<String>('shell-page');
const ValueKey<String> _pageSheetKey = ValueKey<String>('page-sheet-body');
const ValueKey<String> _innerSheetKey = ValueKey<String>('inner-sheet-body');

void main() {
  testWidgets('a sheet over a page sheet recedes the page one more step', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(402 * 3, 874 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final colorTheme = buildDarkColorTheme();
    late BuildContext shellContext;
    late BuildContext pageSheetContext;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          theme: buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
          home: StarSheetBackdrop(
            child: Scaffold(
              body: Builder(
                builder: (BuildContext c) {
                  shellContext = c;
                  return const SizedBox.expand(key: _shellKey);
                },
              ),
            ),
          ),
        ),
      ),
    );

    unawaited(
      StarPageSheet.showScrollable<void>(
        shellContext,
        title: 'Settings',
        presentation: StarPageSheetPresentation.root,
        builder:
            (BuildContext c, ScrollController controller, VoidCallback close) {
              pageSheetContext = c;
              return ListView(
                key: _pageSheetKey,
                controller: controller,
                children: <Widget>[
                  for (int i = 0; i < 20; i++)
                    SizedBox(height: 60, child: Text('Row $i')),
                ],
              );
            },
      ),
    );
    await tester.pumpAndSettle();

    final Rect shellBefore = tester.getRect(find.byKey(_shellKey));
    final Rect pageSheetBefore = tester.getRect(find.byKey(_pageSheetKey));

    unawaited(
      StarBottomSheet.showScrollable<void>(
        pageSheetContext,
        title: 'Licence',
        useRootNavigator: true,
        builder: (BuildContext c, ScrollController controller, _) {
          return SingleChildScrollView(
            controller: controller,
            child: const SizedBox(key: _innerSheetKey, height: 2000),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(_innerSheetKey), findsOneWidget);
    final Rect shellAfter = tester.getRect(find.byKey(_shellKey));
    final Rect pageSheetAfter = tester.getRect(find.byKey(_pageSheetKey));
    expect(shellAfter.width, lessThan(shellBefore.width * 0.95));
    expect(shellAfter.center.dx, moreOrLessEquals(shellBefore.center.dx));
    expect(shellAfter.top, lessThan(shellBefore.top));
    expect(shellAfter.width, lessThan(pageSheetAfter.width));
    expect(pageSheetAfter.width, lessThan(pageSheetBefore.width * 0.95));
    expect(
      pageSheetAfter.center.dx,
      moreOrLessEquals(pageSheetBefore.center.dx),
    );

    Navigator.of(pageSheetContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(_pageSheetKey)),
      rectMoreOrLessEquals(pageSheetBefore),
    );
    expect(
      tester.getRect(find.byKey(_shellKey)),
      rectMoreOrLessEquals(shellBefore),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
