import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_preview_card.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../helpers/test_l10n.dart';

void main() {
  testWidgets('caps tall preview content', (tester) async {
    final colorTheme = buildDarkColorTheme();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final double maxHeight = messagePreviewMaxHeight(context);
              return MessagePreviewCard(
                child: SizedBox(
                  height: maxHeight * 3,
                  child: const Text('tall'),
                ),
              );
            },
          ),
        ),
      ),
    );

    final previewFinder = find.byType(MessagePreviewCard);
    expect(previewFinder, findsOneWidget);
    final RenderBox previewBox = tester.renderObject(previewFinder);
    final double maxHeight = messagePreviewMaxHeight(
      tester.element(previewFinder),
    );
    expect(previewBox.size.height, lessThanOrEqualTo(maxHeight + 32));
    await tester.binding.setSurfaceSize(null);
  });
}
