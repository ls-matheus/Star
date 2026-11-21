// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_item.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_row_layout.dart';
import 'package:star_app/features/settings/providers/preferences/chat_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/time_format_providers.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/user_date_formatting.dart';
import 'package:star_dart/export.dart';

import '../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../helpers/message_item_test_overrides.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/rendered_text_test_helpers.dart';
import '../../../../../helpers/test_l10n.dart';

List<String> _renderedTexts(WidgetTester tester) =>
    renderedTextContents(tester);

Message _message() {
  final DateTime timestamp = DateTime(2026, 1, 1, 12);
  return Message(
    id: '1',
    channelId: 'c1',
    authorId: '123456789012345678',
    authorName: 'Alice',
    webhookId: 'wh1',
    content: 'hello world',
    timestamp: timestamp,
  );
}

MessageRenderSettings _settings({
  bool messageDisplayCompact = true,
  bool showUserAvatarsInCompactMode = false,
}) => MessageRenderSettings(
  activeGuildId: null,
  renderEmbeds: false,
  renderReactions: false,
  inlineAttachmentMedia: false,
  renderSpoilers: RenderSpoilers.onClick,
  revealSpoilers: false,
  chatPreferences: const ChatPreferencesState(),
  messageGroupSpacing: 0,
  messageDisplayCompact: messageDisplayCompact,
  showUserAvatarsInCompactMode: showUserAvatarsInCompactMode,
);

Widget _app(Widget child, {bool use12Hour = false, Size? viewportSize}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [
      starDatabaseProvider.overrideWithValue(_database),
      instanceRuntimeConfigOverride(),
      ...messageItemTestProviderOverrides(),
      use12HourTimeFormatProvider.overrideWithValue(use12Hour),
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
      builder: viewportSize == null
          ? null
          : (context, appChild) => MediaQuery(
              data: MediaQuery.of(context).copyWith(size: viewportSize),
              child: appChild!,
            ),
      home: Scaffold(body: child),
    ),
  );
}

late StarDatabase _database;

void main() {
  setUp(() {
    _database = openTestDatabase();
  });

  group('MessageItem compact layout', () {
    messageItemTestWidgets(
      'dense mode shows inline author prefix and timestamp',
      (tester) async {
        await tester.pumpWidget(
          _app(MessageItem(message: _message(), renderSettings: _settings())),
        );
        await tester.pump();

        expect(find.textContaining('Alice'), findsOneWidget);
        expect(find.text(':'), findsOneWidget);
        final DateTime timestamp = DateTime(2026, 1, 1, 12);
        final String expectedTime = formatUserTime(
          timestamp,
          kTestLocale.toString(),
          use12Hour: false,
        );
        expect(find.text(expectedTime), findsOneWidget);
        expect(find.text('[$expectedTime]'), findsNothing);
        expect(find.byType(StarAvatar), findsNothing);
      },
    );

    messageItemTestWidgets('dense mode can show compact avatars when enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MessageItem(
            message: _message(),
            renderSettings: _settings(showUserAvatarsInCompactMode: true),
          ),
        ),
      );
      await tester.pump();

      final StarAvatar avatar = tester.widget<StarAvatar>(
        find.byType(StarAvatar),
      );
      expect(avatar.size, kCompactAvatarSize);
    });
    messageItemTestWidgets('wide grouped dense rows keep the author prefix', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          MessageItem(
            message: _message(),
            isGrouped: true,
            renderSettings: _settings(),
          ),
          viewportSize: const Size(1400, 900),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.text(':'), findsOneWidget);
    });

    messageItemTestWidgets(
      'mobile grouped dense rows keep body padding without author',
      (tester) async {
        await tester.pumpWidget(
          _app(
            MessageItem(
              message: _message(),
              isGrouped: true,
              renderSettings: _settings(),
            ),
            viewportSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Alice'), findsNothing);
        expect(_renderedTexts(tester), contains('hello world'));
      },
    );

    messageItemTestWidgets(
      'mobile grouped messages align with group-start text',
      (tester) async {
        await tester.pumpWidget(
          _app(
            Column(
              children: [
                MessageItem(message: _message(), renderSettings: _settings()),
                MessageItem(
                  message: Message(
                    id: '2',
                    channelId: 'c1',
                    authorId: '123456789012345678',
                    authorName: 'Alice',
                    webhookId: 'wh1',
                    content: 'follow up',
                    timestamp: DateTime(2026, 1, 1, 12, 1),
                  ),
                  isGrouped: true,
                  renderSettings: _settings(),
                ),
              ],
            ),
            viewportSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        final Finder groupStartText = findRenderedTextContaining('hello world');
        final Finder groupedText = findRenderedTextContaining('follow up');
        expect(groupStartText, findsOneWidget);
        expect(groupedText, findsOneWidget);
        expect(
          tester.getTopLeft(groupStartText).dx,
          tester.getTopLeft(groupedText).dx,
        );
      },
    );
  });
}
