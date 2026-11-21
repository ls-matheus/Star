import 'package:flutter_test/flutter_test.dart';
import 'package:star_markdown/src/config/star_markdown_config.dart';
import 'package:star_markdown/src/widgets/star_markdown.dart';
import 'package:material_ui/material_ui.dart';
import 'support/native_test_parser.dart';

String? _noopUnicodeEmojiUrl(String unicode) => null;

String _noopCustomEmojiUrl({
  required String id,
  required bool animated,
  required int size,
}) => '';

StarMarkdownConfig _configWithTimestamp(StarTimestampFormatter formatter) {
  return StarMarkdownConfig(
    unicodeEmojiUrlBuilder: _noopUnicodeEmojiUrl,
    customEmojiUrlBuilder: _noopCustomEmojiUrl,
    timestampFormatter: formatter,
  );
}

Future<void> _pumpTimestamp(
  WidgetTester tester,
  StarTimestampFormatter formatter,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StarMarkdown(
          astParser: parseTestMarkdownAst,
          data: '<t:1618936830:t>',
          config: _configWithTimestamp(formatter),
          baseStyle: const TextStyle(fontSize: 16),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('timestamp formatter output changes invalidate cached body', (
    tester,
  ) async {
    await _pumpTimestamp(tester, (DateTime _, String _) => 'morning');
    expect(find.textContaining('morning', findRichText: true), findsOneWidget);

    await _pumpTimestamp(tester, (DateTime _, String _) => 'evening');
    expect(find.textContaining('evening', findRichText: true), findsOneWidget);
    expect(find.textContaining('morning', findRichText: true), findsNothing);
  });
}
