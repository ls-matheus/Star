import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/message_character_counter.dart';
import 'package:star_app/features/ui/character_counter/star_character_counter.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Widget _buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('MessageCharacterCounter', () {
    testWidgets('hides below 80% threshold', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const MessageCharacterCounter(
            currentLength: 100,
            maxLength: 200,
            canUpgrade: false,
            premiumMaxLength: 4000,
          ),
        ),
      );

      expect(find.byType(StarCharacterCounter), findsNothing);
    });

    testWidgets('shows counter above 80% threshold', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const MessageCharacterCounter(
            currentLength: 170,
            maxLength: 200,
            canUpgrade: false,
            premiumMaxLength: 4000,
            showTooltip: false,
          ),
        ),
      );

      expect(find.byType(StarCharacterCounter), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });
  });
}
