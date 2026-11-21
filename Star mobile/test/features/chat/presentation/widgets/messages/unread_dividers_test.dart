import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/unread_dividers.dart';
import 'package:star_app/features/chat/providers/chat_wallpaper_provider.dart';
import 'package:star_app/features/chat/wallpaper/chat_wallpaper.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/user_date_formatting.dart';

import '../../../../../helpers/test_l10n.dart';

void main() {
  for (final ChatWallpaperKind kind in <ChatWallpaperKind>[
    ChatWallpaperKind.defaultTheme,
    ChatWallpaperKind.starfield,
  ]) {
    testWidgets('the unread line stops at the date label on ${kind.name}', (
      WidgetTester tester,
    ) async {
      final DateTime date = DateTime(2026, 10, 14, 12);
      final colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatWallpaperProvider.overrideWith(() => _FixedWallpaper(kind)),
          ],
          child: MaterialApp(
            locale: kTestLocale,
            localizationsDelegates: starLocalizationsDelegates,
            supportedLocales: StarLocalizations.supportedLocales,
            theme: buildStarTheme(
              colorTheme: colorTheme,
              textTheme: StarTextTheme.fromColors(colorTheme),
              layoutTheme: StarLayoutTheme.scaled(),
            ),
            home: Scaffold(
              body: Center(child: UnreadDateSeparator(date: date)),
            ),
          ),
        ),
      );

      final Rect divider = tester.getRect(find.byType(UnreadDateSeparator));
      final Rect label = tester.getRect(
        find.text(formatUserFullDate(date, kTestLocale.toString())),
      );
      expect(label.center.dx, moreOrLessEquals(divider.center.dx));
      expect(find.text('NEW'), findsOneWidget);

      final Color line = colorTheme.statusDanger.withValues(alpha: 0.4);
      final Iterable<Rect> lines = tester
          .widgetList<Container>(find.byType(Container))
          .where((Container c) => c.color == line)
          .map((Container c) => tester.getRect(find.byWidget(c)));
      expect(lines, hasLength(2));
      for (final Rect segment in lines) {
        expect(
          segment.right <= label.left || segment.left >= label.right,
          isTrue,
          reason: 'segment $segment crosses label $label',
        );
      }
    });
  }
}

class _FixedWallpaper extends ChatWallpaper {
  _FixedWallpaper(this.kind);

  final ChatWallpaperKind kind;

  @override
  ChatWallpaperSnapshot build() =>
      ChatWallpaperSnapshot(selection: ChatWallpaperState(kind: kind));
}
