import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/spoiler_overlay.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_markdown/star_markdown.dart';

import '../../../../../helpers/test_l10n.dart';

void main() {
  testWidgets('child is tappable after the overlay is revealed', (
    tester,
  ) async {
    var childTaps = 0;
    await _pumpOverlay(tester, onChildTap: () => childTaps++);

    await tester.tap(find.byType(SpoilerOverlay));
    await tester.pumpAndSettle();
    expect(childTaps, 0);

    await tester.tap(find.byType(SpoilerOverlay));
    await tester.pumpAndSettle();
    expect(childTaps, 1);
  });

  testWidgets('stays revealed after remount with the same sync controller', (
    tester,
  ) async {
    final StarSpoilerSyncController controller =
        StarSpoilerSyncController();
    addTearDown(controller.dispose);
    const List<String> syncKeys = <String>['attachment:message-1:image-1'];
    var childTaps = 0;

    await _pumpOverlay(
      tester,
      onChildTap: () => childTaps++,
      controller: controller,
      syncKeys: syncKeys,
    );
    await tester.tap(find.byType(SpoilerOverlay));
    await tester.pumpAndSettle();
    expect(childTaps, 0);

    await _pumpOverlay(
      tester,
      onChildTap: () => childTaps++,
      controller: controller,
      syncKeys: syncKeys,
      key: UniqueKey(),
    );
    await tester.tap(find.byType(SpoilerOverlay));
    await tester.pumpAndSettle();
    expect(childTaps, 1);
  });

  testWidgets('covers again after remount with a new sync controller', (
    tester,
  ) async {
    final StarSpoilerSyncController firstController =
        StarSpoilerSyncController();
    addTearDown(firstController.dispose);
    const List<String> syncKeys = <String>['attachment:message-1:image-1'];
    var childTaps = 0;

    await _pumpOverlay(
      tester,
      onChildTap: () => childTaps++,
      controller: firstController,
      syncKeys: syncKeys,
    );
    await tester.tap(find.byType(SpoilerOverlay));
    await tester.pumpAndSettle();
    expect(childTaps, 0);

    final StarSpoilerSyncController secondController =
        StarSpoilerSyncController();
    addTearDown(secondController.dispose);
    await _pumpOverlay(
      tester,
      onChildTap: () => childTaps++,
      controller: secondController,
      syncKeys: syncKeys,
      key: UniqueKey(),
    );

    await tester.tap(find.byType(SpoilerOverlay));
    await tester.pumpAndSettle();
    expect(childTaps, 0);

    await tester.tap(find.byType(SpoilerOverlay));
    await tester.pumpAndSettle();
    expect(childTaps, 1);
  });
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required VoidCallback onChildTap,
  StarSpoilerSyncController? controller,
  List<String> syncKeys = const <String>[],
  Key? key,
}) {
  return tester.pumpWidget(
    _buildTestApp(
      child: SpoilerOverlay(
        key: key,
        isSpoiler: true,
        initiallyRevealed: false,
        spoilerSyncController: controller,
        syncKeys: syncKeys,
        child: GestureDetector(
          onTap: onChildTap,
          child: const SizedBox(
            width: 120,
            height: 80,
            child: ColoredBox(color: Color(0xFF123456)),
          ),
        ),
      ),
    ),
  );
}

Widget _buildTestApp({required Widget child}) {
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
