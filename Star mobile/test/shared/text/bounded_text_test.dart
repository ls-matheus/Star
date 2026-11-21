import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_markdown/star_markdown.dart';

const String kZalgoSample =
    'Z\u0300\u0301\u0302\u0303\u0304\u0305\u0306\u0307'
    'a\u0300\u0301\u0302\u0303\u0304\u0305\u0306\u0307'
    'l\u0300\u0301\u0302\u0303\u0304\u0305\u0306\u0307'
    'g\u0300\u0301\u0302\u0303\u0304\u0305\u0306\u0307'
    'o\u0300\u0301\u0302\u0303\u0304\u0305\u0306\u0307';

void main() {
  testWidgets('bounded text clips Zalgo overflow in a fixed height row', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            height: 24,
            width: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: Colors.red)),
              child: const Text(
                kZalgoSample,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, height: 1.25),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(StarBoundedTextClip), findsOneWidget);
    expect(find.textContaining('Z'), findsOneWidget);

    final RenderBox box = tester.renderObject<RenderBox>(
      find.byType(SizedBox).first,
    );
    expect(box.size.height, 24);
  });

  testWidgets('multiline text renders without bounded clip wrapper', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Text(
            'Hello from the message list',
            style: TextStyle(fontSize: 16, height: 1.375),
          ),
        ),
      ),
    );

    expect(find.byType(StarBoundedTextClip), findsNothing);
    expect(find.text('Hello from the message list'), findsOneWidget);
  });

  test('boundedStrutFor forces strut height for single-line text', () {
    final StrutStyle strut = boundedStrutFor(
      const TextStyle(fontSize: 16, height: 1.375),
    );
    expect(strut.forceStrutHeight, isTrue);
    expect(strut.height, 1.375);
  });

  test('boundedStrutFor can leave line height flexible for inline widgets', () {
    final StrutStyle strut = boundedStrutFor(
      const TextStyle(fontSize: 16, height: 1.375),
      forceHeight: false,
    );
    expect(strut.forceStrutHeight, isFalse);
  });

  testWidgets('buildStarBoundedRichText always clips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: buildStarBoundedRichText(
            text: const TextSpan(
              text: kZalgoSample,
              style: TextStyle(fontSize: 16, height: 1.375),
            ),
            baseStyle: const TextStyle(fontSize: 16, height: 1.375),
          ),
        ),
      ),
    );

    expect(find.byType(StarBoundedTextClip), findsOneWidget);
  });

  test('inlineSpanHasWidget walks nested spans', () {
    expect(inlineSpanHasWidget(const TextSpan(text: 'hello')), isFalse);
    expect(
      inlineSpanHasWidget(
        const TextSpan(
          children: [
            TextSpan(text: 'a'),
            WidgetSpan(child: SizedBox.shrink()),
          ],
        ),
      ),
      isTrue,
    );
  });
}
