import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/badge/star_guild_badge.dart';
import 'package:star_app/features/ui/badge/star_guild_seal_icon.dart';
import 'package:star_app/material_ui.dart';

Widget _app(List<String> features) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(
        body: Center(child: StarGuildBadge(features: features)),
      ),
    ),
  );
}

void main() {
  testWidgets('partnered communities show the partnered seal', (tester) async {
    await tester.pumpWidget(_app(const <String>['PARTNERED', 'VERIFIED']));

    final StarGuildSealIcon seal = tester.widget<StarGuildSealIcon>(
      find.byType(StarGuildSealIcon),
    );
    expect(seal.kind, StarGuildSealKind.partnered);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('verified communities show the verified seal', (tester) async {
    await tester.pumpWidget(_app(const <String>['VERIFIED']));

    final StarGuildSealIcon seal = tester.widget<StarGuildSealIcon>(
      find.byType(StarGuildSealIcon),
    );
    expect(seal.kind, StarGuildSealKind.verified);
  });

  testWidgets('discoverable communities show the discoverable seal', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const <String>['DISCOVERABLE']));

    final StarGuildSealIcon seal = tester.widget<StarGuildSealIcon>(
      find.byType(StarGuildSealIcon),
    );
    expect(seal.kind, StarGuildSealKind.discoverable);
    expect(find.byType(Image), findsNothing);
  });
}
