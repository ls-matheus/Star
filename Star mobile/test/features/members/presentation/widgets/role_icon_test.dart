import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/members/domain/member.dart';
import 'package:star_app/features/members/presentation/widgets/role_icon.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/widgets/unicode_emoji_widget.dart';

import '../../../../helpers/test_l10n.dart';

Widget _wrap(Widget child) {
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
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders unicode emoji when role has unicode icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const RoleIcon(
          role: MemberRole(id: '1', name: 'Mod', color: 0, unicodeEmoji: '🛡️'),
          size: 20,
          decorative: true,
        ),
      ),
    );
    expect(find.byType(UnicodeEmojiWidget), findsOneWidget);
  });

  testWidgets('renders nothing when role has no icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const RoleIcon(
          role: MemberRole(id: '1', name: 'Mod', color: 0),
          size: 20,
        ),
      ),
    );
    expect(find.byType(UnicodeEmojiWidget), findsNothing);
    expect(find.byType(RoleIcon), findsOneWidget);
    expect(tester.getSize(find.byType(RoleIcon)), Size.zero);
  });
}
