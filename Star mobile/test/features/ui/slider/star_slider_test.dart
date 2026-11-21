import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/slider/star_slider.dart';
import 'package:star_app/material_ui.dart';

import '../../../helpers/test_l10n.dart';

Widget _app(Widget child) {
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
    home: Scaffold(
      body: Center(child: SizedBox(width: 210, child: child)),
    ),
  );
}

String? _sliderValue(WidgetTester tester) {
  return tester
      .widgetList<Semantics>(
        find.descendant(
          of: find.byType(StarSlider),
          matching: find.byType(Semantics),
        ),
      )
      .firstWhere((Semantics s) => s.properties.slider ?? false)
      .properties
      .value;
}

void main() {
  testWidgets('controlled slider follows a drag and commits the new value', (
    tester,
  ) async {
    double value = 100;
    final List<double> live = <double>[];
    final List<double> committed = <double>[];
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => StarSlider(
            value: value,
            defaultValue: value,
            maxValue: 200,
            markers: const <double>[0, 50, 100, 150, 200],
            step: 1,
            asValueChanges: live.add,
            onValueChange: (double next) {
              committed.add(next);
              setState(() => value = next);
            },
          ),
        ),
      ),
    );

    final Finder slider = find.byType(StarSlider);
    final Offset start = tester.getCenter(slider);
    final TestGesture gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-50, 0));
    await tester.pump();

    expect(double.parse(_sliderValue(tester)!), lessThan(100));

    await gesture.up();
    await tester.pump();

    expect(live, isNotEmpty);
    expect(committed, hasLength(1));
    expect(committed.single, lessThan(100));
    expect(committed.single, live.last);
    expect(value, committed.single);
  });

  testWidgets('controlled slider shows the parent value when idle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const StarSlider(value: 40, defaultValue: 40, step: 1)),
    );
    expect(_sliderValue(tester), '40.0');
  });

  testWidgets('RTL maps the left of the track to the maximum', (tester) async {
    double? committed;
    await tester.pumpWidget(
      _app(
        Directionality(
          textDirection: TextDirection.rtl,
          child: StarSlider(
            value: 100,
            defaultValue: 100,
            maxValue: 200,
            step: 1,
            onValueChange: (double next) => committed = next,
          ),
        ),
      ),
    );
    final Rect bounds = tester.getRect(find.byType(StarSlider));
    await tester.tapAt(bounds.centerLeft + const Offset(20, 0));
    await tester.pump();
    expect(committed, greaterThan(150));

    await tester.tapAt(bounds.centerRight - const Offset(20, 0));
    await tester.pump();
    expect(committed, lessThan(50));
  });
}
