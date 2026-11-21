import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/providers/channel_providers.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/slowmode_indicator.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/features/chat/providers/slowmode/slowmode_immunity_provider.dart';
import 'package:star_app/features/chat/providers/slowmode/slowmode_tracker.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

import '../../../../../helpers/test_l10n.dart';

Widget _slowmodeTestApp({
  required ProviderContainer container,
  required Widget child,
}) {
  final StarColorTheme colorTheme = buildDarkColorTheme();
  return UncontrolledProviderScope(
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
        child: Scaffold(body: child),
      ),
    ),
  );
}

ProviderContainer _makeSlowmodeContainer() {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      chatViewModelProvider.overrideWithValue(_chatState()),
      channelByIdProvider('channel-1').overrideWith(
        (ref) => Stream<Channel?>.value(
          const Channel(
            id: 'channel-1',
            guildId: 'guild-1',
            name: 'general',
            rateLimitPerUser: 30,
          ),
        ),
      ),
      isSlowmodeImmuneProvider(
        'channel-1',
      ).overrideWith((ref) => Future<bool>.value(false)),
    ],
  );
  addTearDown(container.dispose);
  return container;
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

void main() {
  testWidgets('wide slowmode indicator does not show immune while loading', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        chatViewModelProvider.overrideWithValue(_chatState()),
        channelByIdProvider('channel-1').overrideWith(
          (ref) => Stream<Channel?>.value(
            const Channel(
              id: 'channel-1',
              guildId: 'guild-1',
              name: 'general',
              rateLimitPerUser: 30,
            ),
          ),
        ),
        isSlowmodeImmuneProvider(
          'channel-1',
        ).overrideWith((ref) => Completer<bool>().future),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _slowmodeTestApp(container: container, child: const SlowmodeIndicator()),
    );
    await tester.pump();

    expect(find.text('Slowmode is enabled'), findsOneWidget);
    await tester.longPress(find.text('Slowmode is enabled'));
    await tester.pumpAndSettle();
    expect(
      find.text('Slowmode is set to 30s for this channel.'),
      findsOneWidget,
    );
    expect(find.textContaining('immune'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('wide slowmode indicator shows enabled copy and trailing clock', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = _makeSlowmodeContainer();
    await tester.pumpWidget(
      _slowmodeTestApp(container: container, child: const SlowmodeIndicator()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Slowmode is enabled'), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.clock), findsOneWidget);
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
    expect(find.byType(StarTooltip), findsOneWidget);
    await tester.longPress(find.text('Slowmode is enabled'));
    await tester.pumpAndSettle();
    expect(
      find.text('Slowmode is set to 30s for this channel.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('wide slowmode indicator shows active countdown copy', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = _makeSlowmodeContainer();
    container
        .read(slowmodeTrackerProvider.notifier)
        .updateCooldownRemaining('channel-1', 30_000);
    await tester.pumpWidget(
      _slowmodeTestApp(container: container, child: const SlowmodeIndicator()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Slowmode is active'), findsOneWidget);
    expect(find.textContaining('00:30'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('compact slowmode indicator keeps duration label format', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container = _makeSlowmodeContainer();
    await tester.pumpWidget(
      _slowmodeTestApp(
        container: container,
        child: const SlowmodeIndicator(compact: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('30s slowmode'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
