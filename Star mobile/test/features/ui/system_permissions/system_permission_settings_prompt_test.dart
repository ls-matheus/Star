import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/system_permissions/system_permission_kind.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/system_permissions/system_permission_settings_prompt.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/test_l10n.dart';

Widget _buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      locale: kTestLocale,
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
  group('SystemPermissionSettingsPrompt', () {
    testWidgets('shows microphone copy and actions', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  unawaited(
                    SystemPermissionSettingsPrompt.show(
                      context,
                      kind: SystemPermissionKind.microphone,
                    ),
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

      final StarLocalizations l10n = StarLocalizations.of(
        tester.element(find.byType(ElevatedButton)),
      );
      expect(find.text(l10n.systemPermissionSettingsTitle), findsOneWidget);
      expect(
        find.text(l10n.systemPermissionMicrophoneMessage('Star')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          StarButton,
          l10n.systemPermissionSettingsOpenSettings,
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(StarButton, l10n.cancel), findsOneWidget);
    });
  });
}
