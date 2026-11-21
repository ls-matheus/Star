import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_header.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

import '../../../../helpers/instance_runtime_config_override.dart';
import '../../../../helpers/rendered_text_test_helpers.dart';
import '../../../../helpers/test_l10n.dart';

Widget _buildApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [instanceRuntimeConfigOverride()],
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

Widget _buildHeader(String displayName) {
  return UserProfileHeader(
    username: 'sampleuser',
    discriminator: '0000',
    displayName: displayName,
    badges: const [],
    customStatus: null,
  );
}

void main() {
  group('UserProfileHeader', () {
    testWidgets(
      'uses resolved display name as title and username tag subtitle',
      (tester) async {
        for (final titleText in ['Sample User', 'sampleuser']) {
          await tester.pumpWidget(_buildApp(_buildHeader(titleText)));

          final header = find.byType(UserProfileHeader);
          final titleFinder = find.descendant(
            of: header,
            matching: findAppText(titleText),
          );
          final tagFinder = find.descendant(
            of: header,
            matching: findAppText('sampleuser#0000'),
          );
          final title = tester.widget<Text>(titleFinder);
          final tag = tester.widget<Text>(tagFinder);

          expect(header, findsOneWidget);
          expect(titleFinder, findsOneWidget);
          expect(title.style?.fontSize, 24);
          expect(tagFinder, findsOneWidget);
          expect(tag.style?.fontSize, isNot(24));
        }
      },
    );

    testWidgets('shows caret and calls onDisplayNameTap when provided', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildApp(
          UserProfileHeader(
            username: 'sampleuser',
            discriminator: '0000',
            displayName: 'Sample User',
            badges: const [],
            customStatus: null,
            onDisplayNameTap: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(PhosphorIconsBold.caretDown), findsOneWidget);
      await tester.tap(find.text('Sample User'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
