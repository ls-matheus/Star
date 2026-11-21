import 'package:flutter/widgets.dart' as widgets;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/embeds/embed_rich.dart';
import 'package:star_app/features/chat/utils/embeds/embed_gallery_utils.dart';
import 'package:star_app/features/settings/domain/search_provider_engine.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/markdown/message_markdown_settings.dart';

const List<String> _linkTexts = <String>[
  'GitHub',
  'hampus',
  'Pull request opened',
  '39ce1a5',
  'compose-start-interval',
  'footer link',
];

Widget _wrap(Widget child, {required bool underline}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      home: Scaffold(
        body: MessageMarkdownSettingsScope(
          settings: MessageMarkdownSettings(
            use12Hour: false,
            alwaysUnderlineLinks: underline,
            dimStrikethroughText: true,
            animateCustomEmoji: true,
            enableTextSelection: false,
            searchEngines: const SearchEnginesState(),
          ),
          child: child,
        ),
      ),
    ),
  );
}

void _collect(
  InlineSpan span,
  TextStyle inherited,
  Map<String, TextDecoration?> out,
) {
  if (span is! TextSpan) {
    return;
  }
  final TextStyle style = inherited.merge(span.style);
  final String? text = span.text;
  if (text != null && text.isNotEmpty) {
    out[text] = style.decoration;
  }
  for (final InlineSpan child in span.children ?? const <InlineSpan>[]) {
    _collect(child, style, out);
  }
}

Map<String, TextDecoration?> _decorations(WidgetTester tester) {
  final Map<String, TextDecoration?> out = <String, TextDecoration?>{};
  for (final widgets.RichText rich in tester.widgetList<widgets.RichText>(
    find.byType(widgets.RichText),
  )) {
    _collect(rich.text, const TextStyle(), out);
  }
  return out;
}

bool _underlined(TextDecoration? decoration) =>
    decoration != null && decoration.contains(TextDecoration.underline);

Future<void> _pump(WidgetTester tester, {required bool underline}) async {
  const Embed embed = Embed(
    type: EmbedType.rich,
    url: 'https://github.com/starapp/star/pull/3472',
    title: 'Pull request opened',
    description: 'commit [39ce1a5](https://github.com/starapp/star)',
    providerName: 'GitHub',
    providerUrl: 'https://github.com',
    author: EmbedAuthor(name: 'hampus', url: 'https://github.com/hampus'),
    fields: <EmbedField>[
      EmbedField(
        name: 'Branch',
        value: '[compose-start-interval](https://github.com/starapp)',
      ),
    ],
    footer: EmbedFooter(text: '[footer link](https://github.com/starapp)'),
  );
  await tester.pumpWidget(
    _wrap(
      EmbedRich(
        embed: embed,
        galleryIndex: EmbedGalleryIndex(<Embed>[embed]),
        embedIndex: 0,
      ),
      underline: underline,
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('underlines every embed link when links are underlined', (
    tester,
  ) async {
    await _pump(tester, underline: true);
    final Map<String, TextDecoration?> decorations = _decorations(tester);
    for (final String text in _linkTexts) {
      expect(decorations.keys, contains(text));
      expect(_underlined(decorations[text]), isTrue, reason: text);
    }
    expect(_underlined(decorations['Branch']), isFalse);
  });

  testWidgets('underlines no embed link when the setting is off', (
    tester,
  ) async {
    await _pump(tester, underline: false);
    final Map<String, TextDecoration?> decorations = _decorations(tester);
    for (final String text in _linkTexts) {
      expect(decorations.keys, contains(text));
      expect(_underlined(decorations[text]), isFalse, reason: text);
    }
  });
}
