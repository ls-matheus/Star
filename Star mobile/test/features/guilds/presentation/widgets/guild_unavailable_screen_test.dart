import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/guilds/presentation/widgets/guild_unavailable_screen.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

void main() {
  testWidgets('guild not found uses an outline icon and a single title', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const GuildNotFoundScreen()));

    expect(
      find.text("This is not the community you're looking for."),
      findsOneWidget,
    );
    expect(
      find.text(
        "The community you're looking for may have been deleted or you may not have access to it.",
      ),
      findsOneWidget,
    );
    expect(find.text('Go to home'), findsOneWidget);
    expect(find.byType(StarButton), findsOneWidget);

    final PhosphorIcon icon = tester.widget<PhosphorIcon>(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is PhosphorIcon &&
            widget.icon == PhosphorIconsRegular.question,
      ),
    );
    expect(icon.icon, PhosphorIconsRegular.question);
    expect(find.byIcon(PhosphorIconsFill.question), findsNothing);
  });
}

Widget _buildApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: child,
    ),
  );
}
