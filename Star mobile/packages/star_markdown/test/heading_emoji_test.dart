import 'package:flutter_test/flutter_test.dart';
import 'package:star_markdown/src/config/star_markdown_config.dart';
import 'package:star_markdown/src/renderers/star_markdown_renderers.dart';
import 'package:star_markdown/src/utils/jumbo_emoji.dart';
import 'package:star_markdown/src/widgets/star_markdown.dart';
import 'package:material_ui/material_ui.dart';
import 'support/native_test_parser.dart';

const StarMarkdownConfig _testMarkdownConfig = StarMarkdownConfig(
  unicodeEmojiUrlBuilder: _noopUnicodeEmojiUrl,
  customEmojiUrlBuilder: _noopCustomEmojiUrl,
);
const TextStyle _baseStyle = TextStyle(fontSize: 16, height: 1.375);
const String _emoji = '<:thinking:111111111111111111>';

String? _noopUnicodeEmojiUrl(String unicode) => null;

String _noopCustomEmojiUrl({
  required String id,
  required bool animated,
  required int size,
}) => '';

Future<void> _pumpMarkdown(WidgetTester tester, String data) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: StarMarkdown(
            astParser: parseTestMarkdownAst,
            data: data,
            config: _testMarkdownConfig,
            baseStyle: _baseStyle,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<double> _collectEmojiHeights(WidgetTester tester) {
  final Finder emojiFinder = find.byType(StarEmojiWidget);
  final int count = tester.widgetList(emojiFinder).length;
  return List<double>.generate(
    count,
    (int index) => tester.getSize(emojiFinder.at(index)).height,
  );
}

void main() {
  group('heading emoji sizing', () {
    testWidgets('emotes scale with heading level and avoid jumbo size', (
      tester,
    ) async {
      const String input =
          '''
-# $_emoji
#### $_emoji
### $_emoji
## $_emoji
# $_emoji''';

      await _pumpMarkdown(tester, input);
      final List<double> heights = _collectEmojiHeights(tester);

      expect(heights, hasLength(5));
      for (final double height in heights) {
        expect(height, lessThan(kStarMarkdownEmojiSizeJumbo));
      }

      for (var i = 1; i < heights.length; i++) {
        expect(
          heights[i],
          greaterThan(heights[i - 1]),
          reason: 'emoji at index $i should be larger than index ${i - 1}',
        );
      }

      expect(heights[0], closeTo(13 * kStarMarkdownEmojiSizeMultiplier, 1));
      expect(heights[1], closeTo(16 * kStarMarkdownEmojiSizeMultiplier, 1));
      expect(heights[2], closeTo(18 * kStarMarkdownEmojiSizeMultiplier, 1));
      expect(heights[3], closeTo(20 * kStarMarkdownEmojiSizeMultiplier, 1));
      expect(heights[4], closeTo(22 * kStarMarkdownEmojiSizeMultiplier, 1));
    });

    testWidgets('single heading with emoji-only content uses scaled size', (
      tester,
    ) async {
      await _pumpMarkdown(tester, '# $_emoji');

      final Size size = tester.getSize(find.byType(StarEmojiWidget));
      expect(size.height, lessThan(kStarMarkdownEmojiSizeJumbo));
      expect(size.height, closeTo(22 * kStarMarkdownEmojiSizeMultiplier, 1));
    });

    testWidgets('plain emoji-only message still uses jumbo size', (
      tester,
    ) async {
      await _pumpMarkdown(tester, _emoji);

      final Size size = tester.getSize(find.byType(StarEmojiWidget));
      expect(size.height, closeTo(kStarMarkdownEmojiSizeJumbo, 1));
    });
  });
}
