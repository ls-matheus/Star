import 'package:cached_network_image_ce/cached_network_image.dart';
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

CachedNetworkImage _customEmojiImage(WidgetTester tester) {
  final Finder finder = find.byType(CachedNetworkImage);
  expect(finder, findsWidgets);
  return tester.widget<CachedNetworkImage>(finder.first);
}

void _expectSingleAxisContain(CachedNetworkImage image) {
  expect(image.fit, BoxFit.contain);
  expect(image.memCacheHeight, isNull);
  expect(image.memCacheWidth, isNotNull);
  expect(image.memCacheWidth, greaterThan(0));
}

void main() {
  group('custom emoji fit (issue #445)', () {
    testWidgets(
      'inline custom emoji renders with BoxFit.contain and single-axis decode cache',
      (tester) async {
        await _pumpMarkdown(tester, 'hello <:smile:111111111111111111> world');

        final Size size = tester.getSize(find.byType(StarEmojiWidget));
        expect(size.height, lessThan(kStarMarkdownEmojiSizeJumbo));

        _expectSingleAxisContain(_customEmojiImage(tester));
      },
    );

    testWidgets(
      'jumbo custom emoji renders with BoxFit.contain and single-axis decode cache',
      (tester) async {
        await _pumpMarkdown(tester, '<:smile:111111111111111111>');

        final Size size = tester.getSize(find.byType(StarEmojiWidget));
        expect(size.height, closeTo(kStarMarkdownEmojiSizeJumbo, 1));

        _expectSingleAxisContain(_customEmojiImage(tester));
      },
    );

    testWidgets(
      'inline custom emoji decode cache scales with device pixel ratio',
      (tester) async {
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpMarkdown(tester, 'hello <:smile:111111111111111111> world');

        final CachedNetworkImage image = _customEmojiImage(tester);
        _expectSingleAxisContain(image);
        expect(
          image.memCacheWidth,
          (16 * kStarMarkdownEmojiSizeMultiplier * 3).round(),
        );
      },
    );

    testWidgets('animated custom emoji skips decode cache resize', (
      tester,
    ) async {
      await _pumpMarkdown(tester, 'hello <a:smile:111111111111111111> world');

      final CachedNetworkImage image = _customEmojiImage(tester);
      expect(image.fit, BoxFit.contain);
      expect(image.memCacheWidth, isNull);
      expect(image.memCacheHeight, isNull);
    });
  });
}
