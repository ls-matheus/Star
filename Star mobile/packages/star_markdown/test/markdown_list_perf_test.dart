import 'package:flutter_test/flutter_test.dart';
import 'package:star_markdown/src/config/star_markdown_config.dart';
import 'package:star_markdown/src/widgets/star_markdown.dart';
import 'package:material_ui/material_ui.dart';
import 'support/native_test_parser.dart';

const StarMarkdownConfig _testMarkdownConfig = StarMarkdownConfig(
  unicodeEmojiUrlBuilder: _noopUnicodeEmojiUrl,
  customEmojiUrlBuilder: _noopCustomEmojiUrl,
);

const TextStyle _baseStyle = TextStyle(fontSize: 16, height: 1.375);

String? _noopUnicodeEmojiUrl(String unicode) => null;

String _noopCustomEmojiUrl({
  required String id,
  required bool animated,
  required int size,
}) => '';

const List<String> _mixedMessages = <String>[
  'hello world',
  '**bold** *italic* `code`',
  'https://example.com/docs',
  'ping <@123> and @everyone',
  '<:wave:111111111111111111> hi',
  '```dart\nvoid main() {}\n```',
  '||hidden spoiler||',
];

void main() {
  testWidgets('builds a mixed markdown list without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 50,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: StarMarkdown(
                  astParser: parseTestMarkdownAst,
                  data: _mixedMessages[index % _mixedMessages.length],
                  parseCacheKey: 'msg-$index',
                  config: _testMarkdownConfig,
                  baseStyle: _baseStyle,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(StarMarkdown), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 50,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: StarMarkdown(
                  astParser: parseTestMarkdownAst,
                  data: _mixedMessages[index % _mixedMessages.length],
                  parseCacheKey: 'msg-$index',
                  config: _testMarkdownConfig,
                  baseStyle: _baseStyle,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
