import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/sheets/attachment_alt_text_sheet.dart';
import 'package:star_app/material_ui.dart';

import '../../../../helpers/test_l10n.dart';

void main() {
  const attachment = Attachment(
    id: 'att-1',
    filename: 'image.png',
    url: 'https://x/y',
    description: 'old alt',
  );

  Widget buildTestApp({required Future<void> Function(BuildContext) onOpen}) {
    final colorTheme = buildDarkColorTheme();
    return ProviderScope(
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await onOpen(context);
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );
  }

  group('showAttachmentAltTextSheet', () {
    testWidgets('returns entered description on save', (tester) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          onOpen: (context) async {
            result = await showAttachmentAltTextSheet(
              context,
              attachment: attachment,
            );
          },
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final input = find.byType(TextField);
      expect(input, findsOneWidget);
      await tester.enterText(input, 'new alt text');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, 'new alt text');
    });

    testWidgets('returns empty string when description is cleared', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        buildTestApp(
          onOpen: (context) async {
            result = await showAttachmentAltTextSheet(
              context,
              attachment: attachment,
            );
          },
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final input = find.byType(TextField);
      await tester.enterText(input, '');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, '');
    });

    testWidgets('returns null when cancelled', (tester) async {
      String? result = 'initial';
      await tester.pumpWidget(
        buildTestApp(
          onOpen: (context) async {
            result = await showAttachmentAltTextSheet(
              context,
              attachment: attachment,
            );
          },
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
