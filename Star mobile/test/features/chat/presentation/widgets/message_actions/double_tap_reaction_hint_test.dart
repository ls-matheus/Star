import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/message_actions/double_tap_reaction_hint.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/message_ui_preferences_providers.dart';
import 'package:star_app/features/ui/text_link/star_text_link.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

import '../../../../../helpers/test_l10n.dart';

class _FixedAction extends DoubleTapActionPreferences {
  _FixedAction(this.action);

  final DoubleTapActionPreference action;

  @override
  DoubleTapActionPreferencesState build() =>
      DoubleTapActionPreferencesState(action: action);
}

class _FixedModality extends InputModalityNotifier {
  _FixedModality(this.touch);

  final bool touch;

  @override
  bool build() => touch;
}

class _FixedAppearance extends AppearancePreferences {
  _FixedAppearance({required this.alwaysUnderlineLinks});

  final bool alwaysUnderlineLinks;

  @override
  AppearancePreferencesState build() =>
      AppearancePreferencesState(alwaysUnderlineLinks: alwaysUnderlineLinks);
}

Future<void> _pumpHint(
  WidgetTester tester, {
  required DoubleTapActionPreference action,
  bool alwaysUnderlineLinks = false,
  bool touchInput = true,
}) async {
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('1'),
        inputModalityProvider.overrideWith(() => _FixedModality(touchInput)),
        doubleTapActionPreferencesProvider.overrideWith(
          () => _FixedAction(action),
        ),
        appearancePreferencesProvider.overrideWith(
          () => _FixedAppearance(alwaysUnderlineLinks: alwaysUnderlineLinks),
        ),
      ],
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: const Scaffold(body: Center(child: DoubleTapReactionHint())),
      ),
    ),
  );
  await tester.pump();
}

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style!;

void main() {
  testWidgets('react shows the emoji and a link to change it', (
    WidgetTester tester,
  ) async {
    await _pumpHint(tester, action: DoubleTapActionPreference.react);

    expect(find.text(testL10n.doubleTapReactionHint), findsOneWidget);
    expect(find.byType(DoubleTapReactionGlyph), findsOneWidget);
    expect(find.byType(StarTextLink), findsOneWidget);
    final TextStyle link = _styleOf(tester, testL10n.doubleTapReactionEdit);
    expect(
      link.color,
      tester.element(find.byType(DoubleTapReactionHint)).colors.textLink,
    );
    expect(link.decoration, TextDecoration.none);
  });

  testWidgets('the change link follows always underline links', (
    WidgetTester tester,
  ) async {
    await _pumpHint(
      tester,
      action: DoubleTapActionPreference.react,
      alwaysUnderlineLinks: true,
    );

    expect(
      _styleOf(tester, testL10n.doubleTapReactionEdit).decoration,
      TextDecoration.underline,
    );
  });

  testWidgets('edit shows plain text with no emoji or link', (
    WidgetTester tester,
  ) async {
    await _pumpHint(
      tester,
      action: DoubleTapActionPreference.edit,
      alwaysUnderlineLinks: true,
    );

    expect(find.text(testL10n.doubleTapEditHint), findsOneWidget);
    expect(find.text(testL10n.doubleTapReactionHint), findsNothing);
    expect(find.byType(DoubleTapReactionGlyph), findsNothing);
    expect(find.byType(StarTextLink), findsNothing);
    final TextStyle style = _styleOf(tester, testL10n.doubleTapEditHint);
    expect(
      style.color,
      isNot(tester.element(find.byType(DoubleTapReactionHint)).colors.textLink),
    );
    expect(style.decoration, isNot(TextDecoration.underline));
  });

  testWidgets('none shows no hint', (WidgetTester tester) async {
    await _pumpHint(tester, action: DoubleTapActionPreference.none);

    expect(find.text(testL10n.doubleTapReactionHint), findsNothing);
    expect(find.text(testL10n.doubleTapEditHint), findsNothing);
    expect(find.byType(DoubleTapReactionGlyph), findsNothing);
  });

  testWidgets('mouse input shows no hint', (WidgetTester tester) async {
    await _pumpHint(
      tester,
      action: DoubleTapActionPreference.react,
      touchInput: false,
    );

    expect(find.text(testL10n.doubleTapReactionHint), findsNothing);
    expect(find.byType(DoubleTapReactionGlyph), findsNothing);
  });
}
