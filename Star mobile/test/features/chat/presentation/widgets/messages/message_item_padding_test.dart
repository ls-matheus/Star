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
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

import '../../../../../helpers/instance_runtime_config_override.dart';
import '../../../../../helpers/message_item_test_overrides.dart';
import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

Message _message() => Message(
  id: '1',
  channelId: 'c1',
  authorId: '123456789012345678',
  authorName: 'Webhook',
  webhookId: 'wh1',
  content: 'hello world',
  timestamp: DateTime.utc(2026, 1, 1, 12),
);

const MessageRenderSettings _settings = MessageRenderSettings(
  activeGuildId: null,
  renderEmbeds: false,
  renderReactions: false,
  inlineAttachmentMedia: false,
  renderSpoilers: RenderSpoilers.onClick,
  revealSpoilers: false,
  chatPreferences: ChatPreferencesState(),
  messageGroupSpacing: 16,
);

Future<void> _pumpApp(WidgetTester tester, Widget child) {
  final colorTheme = buildDarkColorTheme();
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        starDatabaseProvider.overrideWithValue(_database),
        instanceRuntimeConfigOverride(),
        ...messageItemTestProviderOverrides(),
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
        home: Scaffold(body: child),
      ),
    ),
  );
}

late StarDatabase _database;

void main() {
  setUp(() {
    _database = openTestDatabase();
  });

  group('MessageItem vertical padding', () {
    Future<EdgeInsetsGeometry?> pumpPadding(
      WidgetTester tester, {
      required bool isGrouped,
    }) async {
      await _pumpApp(
        tester,
        MessageItem(
          message: _message(),
          isGrouped: isGrouped,
          renderSettings: _settings,
        ),
      );
      await tester.pump();

      const expectedPadding = EdgeInsetsDirectional.only(
        start: kMessageRowPaddingHorizontal,
        end: kMessageRowPaddingHorizontal,
        top: 2,
        bottom: 2,
      );

      final animatedContainer = find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer && widget.padding == expectedPadding,
      );
      if (tester.any(animatedContainer)) {
        return tester.widget<AnimatedContainer>(animatedContainer).padding;
      }

      final padding = find.byWidgetPredicate(
        (widget) => widget is Padding && widget.padding == expectedPadding,
      );
      expect(padding, findsOneWidget);
      return tester.widget<Padding>(padding).padding;
    }

    messageItemTestWidgets(
      'group-start rows use uniform 2px vertical padding',
      (tester) async {
        expect(
          await pumpPadding(tester, isGrouped: false),
          const EdgeInsetsDirectional.only(
            start: kMessageRowPaddingHorizontal,
            end: kMessageRowPaddingHorizontal,
            top: 2,
            bottom: 2,
          ),
        );
      },
    );

    messageItemTestWidgets(
      'grouped continuation rows use the same 2px padding',
      (tester) async {
        expect(
          await pumpPadding(tester, isGrouped: true),
          const EdgeInsetsDirectional.only(
            start: kMessageRowPaddingHorizontal,
            end: kMessageRowPaddingHorizontal,
            top: 2,
            bottom: 2,
          ),
        );
      },
    );
  });
}
