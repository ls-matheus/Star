import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/input/emoji_text_editing_controller.dart';
import 'package:star_app/features/ui/input/star_clipboard_scope.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/material_ui.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('StarInput', () {
    testWidgets('renders label text above the field', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarInput(label: 'Username')),
      );

      expect(find.text('Username'), findsOneWidget);

      final labelFinder = find.text('Username');
      final fieldFinder = find.byType(TextFormField);

      final labelOffset = tester.getTopLeft(labelFinder);
      final fieldOffset = tester.getTopLeft(fieldFinder);
      expect(labelOffset.dy, lessThan(fieldOffset.dy));
    });

    testWidgets('renders hint text in the field', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarInput(hint: 'Enter your name')),
      );

      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('long errors wrap instead of being cut off', (tester) async {
      const String error =
          "You don't have the permissions required to perform this action in this community.";
      await tester.pumpWidget(
        buildTestApp(const StarInput(hint: 'Hi', errorText: 'Too short')),
      );
      final double oneLine = tester.getSize(find.text('Too short')).height;
      await tester.pumpWidget(
        buildTestApp(const StarInput(hint: 'Hi', errorText: error)),
      );
      expect(
        tester.getSize(find.text(error)).height,
        greaterThan(oneLine * 1.5),
      );
    });

    testWidgets('does not render label when null', (tester) async {
      await tester.pumpWidget(buildTestApp(const StarInput(hint: 'Hi')));

      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.children.whereType<Padding>().length, equals(0));
    });

    testWidgets('multiline constructor sets minLines', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarInput.multiline(hint: 'Write something...')),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.minLines, equals(3));
      expect(editable.maxLines, isNull);
    });

    testWidgets('provides the default text selection context menu', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const StarInput()));

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.contextMenuBuilder, isNotNull);
    });

    testWidgets('wraps token controllers with clipboard scope', (tester) async {
      final EmojiTextEditingController controller =
          EmojiTextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildTestApp(StarInput(controller: controller, hint: 'Bio')),
      );

      expect(find.byType(StarClipboardScope), findsOneWidget);
    });

    testWidgets('paste from the real long press toolbar inserts text', (
      tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      _mockClipboardText('pasted-secret');

      await tester.pumpWidget(
        buildTestApp(StarInput(controller: controller, label: 'Email')),
      );

      await tester.longPress(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.text('Paste'), findsOneWidget);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(controller.text, 'pasted-secret');
    });

    testWidgets('toolbar paste survives a menu rebuild during the press', (
      tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      _mockClipboardText('pasted-secret');

      await tester.pumpWidget(
        buildTestApp(StarInput(controller: controller, label: 'Email')),
      );

      await tester.longPress(find.byType(EditableText));
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Paste')),
      );
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.text, 'pasted-secret');
    });

    testWidgets('suffix icon tap fires callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildTestApp(
          StarInput(
            hint: 'Password',
            suffixIcon: const Icon(Icons.visibility),
            onSuffixTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.visibility));
      expect(tapped, isTrue);
    });

    testWidgets('associates the visible label with the text field', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        buildTestApp(const StarInput(label: 'Username')),
      );

      expect(find.bySemanticsLabel('Username'), findsWidgets);
      expect(find.text('Username'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('multiline text never runs under the suffix button', (
      tester,
    ) async {
      final controller = TextEditingController(
        text: 'Just doing my part to help make Star a bug-free experience!',
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        buildTestApp(
          Padding(
            padding: const EdgeInsets.all(16),
            child: StarInput.multiline(
              controller: controller,
              label: 'About me',
              suffixIcon: const Icon(Icons.emoji_emotions, size: 20),
            ),
          ),
        ),
      );

      final Rect text = tester.getRect(find.byType(EditableText));
      final Rect suffix = tester.getRect(find.byIcon(Icons.emoji_emotions));
      expect(text.right, lessThanOrEqualTo(suffix.left));
    });
  });
}

void _mockClipboardText(String text) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall methodCall,
      ) async {
        if (methodCall.method == 'Clipboard.getData') {
          return <String, String>{'text': text};
        }
        if (methodCall.method == 'Clipboard.hasStrings') {
          return <String, bool>{'value': true};
        }
        return null;
      });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
}
