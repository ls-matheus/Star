import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/auth/presentation/widgets/auth_form_error_text.dart';
import 'package:star_app/material_ui.dart';

Widget _app(Widget child) {
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
  testWidgets('exposes error text as a live region', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _app(const AuthFormErrorText('Invalid email or password')),
    );

    expect(find.bySemanticsLabel('Invalid email or password'), findsOneWidget);
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Invalid email or password'),
    );
    expect(node.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });
}
