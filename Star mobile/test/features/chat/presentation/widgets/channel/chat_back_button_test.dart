import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/chat_back_button.dart';
import 'package:star_app/features/ui/badge/star_badge.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

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
  testWidgets('hides unread badge when count is zero', (tester) async {
    await tester.pumpWidget(
      buildTestApp(ChatBackButton(unreadCount: 0, onPressed: () {})),
    );
    expect(find.byType(StarBadge), findsNothing);
    expect(find.byIcon(PhosphorIconsBold.arrowLeft), findsOneWidget);
  });

  testWidgets('shows unread count badge when count is positive', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(ChatBackButton(unreadCount: 4, onPressed: () {})),
    );
    expect(find.byType(StarBadge), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('large counts use the standard pill with a composer cutout', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(ChatBackButton(unreadCount: 250, onPressed: () {})),
    );
    await tester.pumpAndSettle();

    final StarBadge badge = tester.widget<StarBadge>(
      find.byType(StarBadge),
    );
    expect(badge.cutoutColor, buildDarkColorTheme().chatInputBackground);
    expect(find.text('99+'), findsOneWidget);
    expect(tester.getSize(find.byType(StarBadge)).height, StarBadge.height);
    expect(tester.takeException(), isNull);
  });
}
