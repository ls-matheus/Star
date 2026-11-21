import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/ui/voice/star_live_badge.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

void main() {
  testWidgets('voice tile live badge uses the hud chip decoration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        home: Scaffold(
          body: StarLiveBadge(tone: StarLiveBadgeTone.voiceTile),
        ),
      ),
    );
    await tester.pump();
    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(StarLiveBadge),
        matching: find.byType(DecoratedBox),
      ),
    );
    final BoxDecoration decoration = box.decoration as BoxDecoration;
    expect(decoration.color, kVoiceLiveBadgeRed);
    expect(
      decoration.borderRadius,
      BorderRadius.circular(kVoiceTileHudChipRadius),
    );
    expect(find.text('LIVE'), findsOneWidget);
  });
}
