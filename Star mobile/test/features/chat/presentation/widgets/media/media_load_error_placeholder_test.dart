import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/media/media_load_error_placeholder.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

import '../../../../../helpers/test_l10n.dart';

Widget _app(Widget child) {
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

void main() {
  testWidgets('shows a broken-image icon and load-failed copy', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 240,
          height: 180,
          child: MediaLoadErrorPlaceholder(),
        ),
      ),
    );

    expect(find.text(testL10n.chatImageCouldNotLoad), findsOneWidget);
    expect(find.byIcon(PhosphorIconsBold.imageBroken), findsOneWidget);
    expect(
      tester.getSize(find.byType(MediaLoadErrorPlaceholder)),
      const Size(240, 180),
    );
    expect(
      tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byType(MediaLoadErrorPlaceholder),
              matching: find.byType(ColoredBox),
            ),
          )
          .color,
      buildDarkColorTheme().backgroundSecondaryAlt,
    );
  });

  testWidgets('hides copy when compact', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 56,
          height: 56,
          child: MediaLoadErrorPlaceholder(showLabel: false),
        ),
      ),
    );

    expect(find.text(testL10n.chatImageCouldNotLoad), findsNothing);
    expect(find.byIcon(PhosphorIconsBold.imageBroken), findsOneWidget);
  });
}
