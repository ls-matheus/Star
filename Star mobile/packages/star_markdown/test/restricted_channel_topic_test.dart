import 'package:flutter_test/flutter_test.dart';
import 'package:star_markdown/src/config/star_markdown_config.dart';
import 'package:star_markdown/src/contexts/star_markdown_context.dart';
import 'package:star_markdown/src/contexts/star_markdown_features.dart';
import 'package:star_markdown/src/widgets/star_markdown.dart';
import 'package:material_ui/material_ui.dart';
import 'support/native_test_parser.dart';

const StarMarkdownConfig _testMarkdownConfig = StarMarkdownConfig(
  unicodeEmojiUrlBuilder: _noopUnicodeEmojiUrl,
  customEmojiUrlBuilder: _noopCustomEmojiUrl,
);

String? _noopUnicodeEmojiUrl(String unicode) => null;

String _noopCustomEmojiUrl({
  required String id,
  required bool animated,
  required int size,
}) => 'https://example.com/emoji/$id';

void main() {
  final features = StarMarkdownFeatures.forContext(
    StarMarkdownContext.restrictedChannelTopic,
  );

  group('restricted channel topic', () {
    test('does not collapse to restricted inline preview', () {
      expect(features.isRestrictedInlinePreview, isFalse);
      expect(features.allowHeadings, isFalse);
      expect(features.allowLists, isFalse);
      expect(features.allowBlockquotes, isFalse);
    });

    testWidgets('preserves single newlines in topic text', (tester) async {
      const String input = 'first line\nsecond line';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StarMarkdown(
                astParser: parseTestMarkdownAst,
                data: input,
                config: _testMarkdownConfig,
                context: StarMarkdownContext.restrictedChannelTopic,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final String renderedText = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((RichText richText) => richText.text.toPlainText())
          .join();
      expect(renderedText, contains('first line'));
      expect(renderedText, contains('second line'));
      expect(renderedText, isNot('first line second line'));
    });
  });
}
