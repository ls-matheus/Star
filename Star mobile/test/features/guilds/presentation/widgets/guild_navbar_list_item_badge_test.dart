import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/guilds/presentation/widgets/guild_navbar.dart';
import 'package:star_app/features/ui/badge/star_badge.dart';
import 'package:star_app/material_ui.dart';

import '../../../../helpers/pump_star_app.dart';

void main() {
  for (final bool isSelected in <bool>[false, true]) {
    testWidgets('mention badge shows when isSelected is $isSelected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        pumpStarApp(
          child: Scaffold(
            body: Center(
              child: guildListItemForTest(
                label: 'Sim Lab',
                isSelected: isSelected,
                mentionCount: 1,
              ),
            ),
          ),
        ),
      );
      await pumpStarFramesQuick(tester);

      expect(find.byType(StarBadge), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  }
}
