import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_modal_frame.dart';
import 'package:star_app/features/ui/bottom_sheet/star_sheet_motion.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/material_ui.dart';

import '../../../../helpers/input_modality_override.dart';

Future<ModalRoute<dynamic>?> _open(
  WidgetTester tester, {
  required bool touch,
}) async {
  final colorTheme = buildDarkColorTheme();
  ModalRoute<dynamic>? route;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [inputModalityOverride(touch: touch)],
      child: MaterialApp(
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(
              showWideSettingsBottomSheet(
                context,
                child: Builder(
                  builder: (sheetContext) {
                    route = ModalRoute.of(sheetContext);
                    return const SizedBox(height: 100);
                  },
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return route;
}

void main() {
  testWidgets('wide settings sheet uses the sheet motion tokens', (
    tester,
  ) async {
    final ModalRoute<dynamic>? route = await _open(tester, touch: true);

    expect(route!.transitionDuration, StarMotionTheme.sheetDuration);
    expect(route.reverseTransitionDuration, kStarSheetCloseDuration);
  });

  testWidgets('a mouse opens wide settings as a desktop modal', (tester) async {
    final ModalRoute<dynamic>? route = await _open(tester, touch: false);

    expect(route, isA<StarDesktopRoute<dynamic>>());
    expect(
      (route! as StarDesktopRoute<dynamic>).surface,
      StarDesktopSurface.modal,
    );
  });
}
