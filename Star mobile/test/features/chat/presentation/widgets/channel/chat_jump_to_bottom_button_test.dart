import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/chat_floating_button.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../helpers/test_l10n.dart';

Widget _buildTestApp(Widget child) {
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
    home: Scaffold(body: child),
  );
}

void main() {
  group('ChatJumpToBottomButton', () {
    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildTestApp(ChatJumpToBottomButton(onTap: () => tapped = true)),
      );

      await tester.tap(find.byType(ChatJumpToBottomButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows loading spinner and does not call onTap when loading', (
      WidgetTester tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildTestApp(
          ChatJumpToBottomButton(isLoading: true, onTap: () => tapped = true),
        ),
      );

      expect(find.byType(StarLoadingSpinner), findsOneWidget);
      await tester.tap(find.byType(ChatJumpToBottomButton));
      expect(tapped, isFalse);
    });
  });
}
