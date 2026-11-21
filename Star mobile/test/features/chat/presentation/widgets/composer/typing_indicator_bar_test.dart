import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/gateway/providers/gateway_event_providers.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/router/route_state_providers.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/typing_indicator_bar.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/features/friends/providers/blocked_user_ids_provider.dart';
import 'package:star_app/features/ui/avatar/star_avatar_stack.dart';
import 'package:star_app/features/ui/spinner/star_typing_dots.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/guild_user_display_provider.dart';
import 'package:star_app/shared/utils/guild_user_display.dart';
import 'package:star_markdown/star_markdown.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

const String _kTyperUserId = 'user-1';

late ProviderContainer container;

Future<void> _pumpTypingIndicatorBar(
  WidgetTester tester, {
  required bool compact,
}) async {
  container = ProviderContainer(
    overrides: [
      starDatabaseProvider.overrideWithValue(_database),
      chatViewModelProvider.overrideWithValue(_chatState()),
      currentUserIdProvider.overrideWithValue('me'),
      contextualGuildIdProvider.overrideWithValue('guild-1'),
      blockedUserIdsProvider.overrideWithValue(const <String>{}),
      guildUserDisplayProvider((_kTyperUserId, 'guild-1')).overrideWith(
        (ref) => const AsyncValue.data(
          GuildUserDisplay(
            displayName: 'Typer',
            avatarUrl: null,
            avatarColor: null,
            accountDisplayName: 'Typer',
          ),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  final StarColorTheme colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: TypingIndicatorBar(compact: compact)),
        ),
      ),
    ),
  );
  container
      .read(typingIndicatorsProvider(readAccountUserId(container)).notifier)
      .addTyping('channel-1', _kTyperUserId);
  await tester.pump();
}

ChatViewState _chatState() {
  return const ChatViewState(
    channelId: 'channel-1',
    messages: <Message>[],
    replyingTo: null,
    replyMentioning: true,
    editingMessage: null,
    messageText: '',
    scrollToBottomSignal: 0,
    isLoading: false,
    isSyncingMessages: false,
    isLoadingMore: false,
    isLoadingNewer: false,
    hasMoreMessages: false,
    hasMoreNewerMessages: false,
    errorMessage: null,
  );
}

late StarDatabase _database;

void main() {
  setUp(() {
    _database = openTestDatabase();
  });

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
  });

  testWidgets('wide typing indicator uses typing dots without pill chrome', (
    WidgetTester tester,
  ) async {
    await _pumpTypingIndicatorBar(tester, compact: false);

    expect(find.byType(StarTypingDots), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(16),
      ),
      findsNothing,
    );
    container
        .read(typingIndicatorsProvider(readAccountUserId(container)).notifier)
        .clearAll();
  });

  testWidgets('typing indicator label avoids bounded text clipping', (
    WidgetTester tester,
  ) async {
    await _pumpTypingIndicatorBar(tester, compact: false);

    expect(find.textContaining('is typing'), findsOneWidget);
    expect(find.byType(StarBoundedTextClip), findsNothing);
    container
        .read(typingIndicatorsProvider(readAccountUserId(container)).notifier)
        .clearAll();
  });

  testWidgets('wide typing indicator uses circular avatar outline rings', (
    WidgetTester tester,
  ) async {
    await _pumpTypingIndicatorBar(tester, compact: false);

    final StarAvatarStack stack = tester.widget<StarAvatarStack>(
      find.byType(StarAvatarStack),
    );
    expect(stack.outlineColor, isNotNull);
    expect(stack.size, 12);
    expect(stack.overlap, -4);
    expect(stack.outlineWidth, 1);
    expect(
      tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((DecoratedBox box) => box.decoration)
          .whereType<BoxDecoration>()
          .where(
            (BoxDecoration decoration) =>
                decoration.shape == BoxShape.circle &&
                decoration.color == stack.outlineColor,
          )
          .length,
      greaterThan(0),
    );
    container
        .read(typingIndicatorsProvider(readAccountUserId(container)).notifier)
        .clearAll();
  });

  testWidgets('compact typing indicator keeps the typing dots', (
    WidgetTester tester,
  ) async {
    await _pumpTypingIndicatorBar(tester, compact: true);

    expect(find.byType(StarTypingDots), findsOneWidget);
    expect(
      tester
          .widget<StarAvatarStack>(find.byType(StarAvatarStack))
          .outlineColor,
      isNotNull,
    );
    container
        .read(typingIndicatorsProvider(readAccountUserId(container)).notifier)
        .clearAll();
  });
}
