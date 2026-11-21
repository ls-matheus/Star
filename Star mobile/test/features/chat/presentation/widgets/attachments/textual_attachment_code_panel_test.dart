import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_fonts.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/textual_attachment_code_panel.dart';
import 'package:star_app/features/chat/utils/attachments/textual_attachment_content.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/widgets/star_bounded_text_widgets.dart'
    as bounded;
import 'package:material_ui/material_ui.dart' as flutter;

import '../../../../../helpers/test_l10n.dart';

void main() {
  testWidgets('plain text preview uses the theme monospace font', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: const TextualAttachmentCodePanel(
          status: TextualAttachmentPreviewStatus.loaded,
          visibleLineCount: 4,
          wrapText: true,
          textContent: 'hello world',
        ),
      ),
    );

    final bounded.Text panelText = tester.widget<bounded.Text>(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is bounded.Text && widget.data == 'hello world',
      ),
    );
    expect(panelText.style?.fontFamily, StarFonts.mono);

    final flutter.Text renderedText = tester.widget<flutter.Text>(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is flutter.Text && widget.data == 'hello world',
      ),
    );
    expect(renderedText.style?.fontFamily, StarFonts.mono);
  });

  testWidgets('highlighted preview uses the theme monospace font', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        child: const TextualAttachmentCodePanel(
          status: TextualAttachmentPreviewStatus.loaded,
          visibleLineCount: 4,
          wrapText: true,
          textContent: 'print("hi")',
          languageCode: 'python',
        ),
      ),
    );

    final Finder highlightFinder = find.byWidgetPredicate(
      (Widget widget) => widget is HighlightView,
    );
    expect(highlightFinder, findsOneWidget);
    final HighlightView view = tester.widget<HighlightView>(highlightFinder);
    expect(view.textStyle?.fontFamily, StarFonts.mono);
    expect(view.theme['root']?.fontFamily, StarFonts.mono);
  });
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
