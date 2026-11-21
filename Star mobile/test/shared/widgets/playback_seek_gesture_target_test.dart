import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/gestures/nested_horizontal_scrollable.dart';
import 'package:star_app/shared/widgets/playback_seek_gesture_target.dart';

Widget _app({required bool enabled}) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(
      body: SizedBox(
        width: 200,
        child: PlaybackSeekGestureTarget(
          enabled: enabled,
          onSeekFraction: (double _) {},
          child: const SizedBox(height: 4, width: double.infinity),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('blocks shell swipe when enabled', (tester) async {
    await tester.pumpWidget(_app(enabled: true));

    expect(find.byKey(kPlaybackSeekShellGestureBlockKey), findsOneWidget);
  });

  testWidgets('does not block shell swipe when disabled', (tester) async {
    await tester.pumpWidget(_app(enabled: false));

    expect(find.byKey(kPlaybackSeekShellGestureBlockKey), findsNothing);
  });
}
