import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/color_picker/star_color_picker_field.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Widget _wrap(Widget child, {Size size = const Size(1200, 800)}) {
  final colorTheme = buildDarkColorTheme();
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

void main() {
  group('StarColorPickerField input', () {
    testWidgets('valid hex typing notifies onChanged for live preview', (
      tester,
    ) async {
      final values = <int>[];
      await tester.pumpWidget(
        _wrap(
          StarColorPickerField(
            value: 0x112233,
            onChanged: values.add,
            label: 'Accent color',
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), '#FF0000');
      await tester.pump();

      expect(values, contains(0xFF0000));
    });

    testWidgets('swatch keeps the alpha of a translucent color', (
      tester,
    ) async {
      const Color translucent = Color(0x1AFFFFFF);
      await tester.pumpWidget(
        _wrap(
          StarColorPickerField(
            value: 0xFFFFFF,
            swatchColor: translucent,
            onChanged: (_) {},
            label: 'Button Secondary Fill',
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is ColoredBox && widget.color == translucent,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is ColoredBox && widget.color == const Color(0xFFFFFFFF),
        ),
        findsNothing,
      );
    });

    testWidgets('incomplete hex does not notify onChanged', (tester) async {
      final values = <int>[];
      await tester.pumpWidget(
        _wrap(
          StarColorPickerField(
            value: 0x112233,
            onChanged: values.add,
            label: 'Accent color',
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), '#FF00');
      await tester.pump();

      expect(values, isEmpty);
    });

    testWidgets('unset value shows #000000 and text-chat swatch', (
      tester,
    ) async {
      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        _wrap(
          StarColorPickerField(
            value: 0,
            onChanged: (_) {},
            label: 'Folder color',
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, '#000000');

      final swatch = tester.widget<ColoredBox>(
        find.descendant(
          of: find.bySemanticsLabel('Open color picker'),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(swatch.color, colorTheme.textChat);
    });

    testWidgets('opening color swatch dismisses hex keyboard focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          StarColorPickerField(
            value: 0x112233,
            onChanged: (_) {},
            label: 'Accent color',
          ),
        ),
      );

      final editableFinder = find.byType(EditableText);
      await tester.tap(editableFinder);
      await tester.pump();
      final editable = tester.widget<EditableText>(editableFinder);
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.tap(find.bySemanticsLabel('Open color picker'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(editable.focusNode.hasFocus, isFalse);
    });
  });
}
