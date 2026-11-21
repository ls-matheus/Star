// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/core/router/route_state_providers.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/data/message_repository.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/message_actions/reply_preview.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:star_app/features/chat/providers/core/chat_providers.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/features/chat/providers/messages/channel_message_stream_provider.dart';
import 'package:star_app/features/chat/utils/messages/channel_message_stream.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/markdown/message_markdown_settings.dart';
import 'package:star_dart/export.dart';

import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/test_l10n.dart';

late StarDatabase _database;

void main() {
  setUp(() {
    _database = openTestDatabase();
  });

  testWidgets('mentions the replied-to author when the reply pings them', (
    tester,
  ) async {
    final parent = _message(
      id: 'parent-1',
      authorId: '1001',
      authorName: 'Sample User',
      authorIsBot: true,
    );
    final reply = _message(
      id: 'reply-1',
      authorId: '1002',
      authorName: 'August',
      type: messageTypeReply,
      mentionedUserIds: const ['1001'],
      messageReference: const MessageReference(
        channelId: 'channel-1',
        messageId: 'parent-1',
        type: MessageReferenceType.valueDefault,
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(
        chatState: _chatState(messages: [parent]),
        child: InlineReplyPreview(message: reply),
      ),
    );

    expect(find.text('@Sample User'), findsOneWidget);
    expect(find.text('Sample User'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('dense mode hides the replied-to author avatar', (tester) async {
    final parent = _message(
      id: 'parent-1',
      authorId: '1001',
      authorName: 'Sample User',
    );
    final reply = _message(
      id: 'reply-1',
      authorId: '1002',
      authorName: 'August',
      type: messageTypeReply,
      messageReference: const MessageReference(
        channelId: 'channel-1',
        messageId: 'parent-1',
        type: MessageReferenceType.valueDefault,
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(
        chatState: _chatState(messages: [parent]),
        child: InlineReplyPreview(message: reply, messageDisplayCompact: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StarAvatar), findsNothing);
    expect(find.byIcon(PhosphorIconsFill.arrowBendUpLeft), findsOneWidget);
    expect(find.text('Sample User'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('cozy mode shows the replied-to author avatar', (tester) async {
    final parent = _message(
      id: 'parent-1',
      authorId: '1001',
      authorName: 'Sample User',
    );
    final reply = _message(
      id: 'reply-1',
      authorId: '1002',
      authorName: 'August',
      type: messageTypeReply,
      messageReference: const MessageReference(
        channelId: 'channel-1',
        messageId: 'parent-1',
        type: MessageReferenceType.valueDefault,
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(
        chatState: _chatState(messages: [parent]),
        child: InlineReplyPreview(message: reply),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StarAvatar), findsOneWidget);
    expect(find.byIcon(PhosphorIconsFill.arrowBendUpLeft), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('hides spoiler text in the replied-to content preview', (
    tester,
  ) async {
    final parent = _message(
      id: 'parent-1',
      authorId: '1001',
      authorName: 'Sample User',
      content: '||top secret||',
    );
    final reply = _message(
      id: 'reply-1',
      authorId: '1002',
      authorName: 'August',
      type: messageTypeReply,
      messageReference: const MessageReference(
        channelId: 'channel-1',
        messageId: 'parent-1',
        type: MessageReferenceType.valueDefault,
      ),
    );

    await tester.pumpWidget(
      _buildTestApp(
        chatState: _chatState(messages: [parent]),
        child: InlineReplyPreview(message: reply),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('top secret'), findsNothing);
    expect(find.byType(GestureDetector), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('reply preview loops the parent message animated custom emoji '
      '(#713)', (tester) async {
    const String content = '<a:party:123456789012345678>';
    final parent = _message(
      id: 'parent-1',
      authorId: '1001',
      authorName: 'Sample User',
      content: content,
    );
    final reply = _message(
      id: 'reply-1',
      authorId: '1002',
      authorName: 'August',
      type: messageTypeReply,
      messageReference: const MessageReference(
        channelId: 'channel-1',
        messageId: 'parent-1',
        type: MessageReferenceType.valueDefault,
      ),
    );
    const Key bodyKey = ValueKey<String>('body');

    await tester.pumpWidget(
      _buildTestApp(
        chatState: _chatState(messages: [parent]),
        child: MessageMarkdownSettingsScope(
          settings: MessageMarkdownSettings.defaults,
          child: Column(
            children: [
              InlineReplyPreview(message: reply),
              const MessageMarkdown(key: bodyKey, data: content),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    List<String> urlsUnder(Finder scope) => tester
        .widgetList<CachedNetworkImage>(
          find.descendant(of: scope, matching: find.byType(CachedNetworkImage)),
        )
        .map((image) => image.imageUrl)
        .toList();

    final List<String> previewUrls = urlsUnder(find.byType(InlineReplyPreview));
    expect(previewUrls, isNotEmpty);
    expect(
      previewUrls.where((url) => url.contains('emojis/123456789012345678')),
      isNotEmpty,
    );
    expect(previewUrls.where((url) => url.contains('animated=true')), isEmpty);
    expect(
      urlsUnder(find.byKey(bodyKey)),
      contains(contains('emojis/123456789012345678.webp?animated=true')),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('an older page landing does not rebuild reply previews already '
      'on screen (#713)', (tester) async {
    final parent = _message(
      id: 'parent-1',
      authorId: '1001',
      authorName: 'Sample User',
      content: 'first draft',
    );
    final reply = _replyTo('parent-1');
    final _TestChatViewModel chatViewModel = _TestChatViewModel(
      _chatState(messages: [parent, reply]),
    );
    await tester.pumpWidget(
      _buildTestApp(
        chatViewModel: chatViewModel,
        child: InlineReplyPreview(message: reply),
      ),
    );
    await tester.pumpAndSettle();

    int previewBuilds = 0;
    debugOnRebuildDirtyWidget = (Element element, bool builtOnce) {
      if (element.widget is InlineReplyPreview) {
        previewBuilds += 1;
      }
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    final older = _message(id: 'older-1', authorId: '1003', authorName: 'Ada');
    chatViewModel.write([older, parent, reply], MessagesOrigin.olderPage);
    await tester.pump();
    expect(
      previewBuilds,
      0,
      reason: 'a page that leaves the parent untouched must not rebuild',
    );

    final editedParent = _message(
      id: 'parent-1',
      authorId: '1001',
      authorName: 'Sample User',
      content: 'final wording',
    );
    chatViewModel.write([
      older,
      editedParent,
      reply,
    ], MessagesOrigin.realtimeEvent);
    await tester.pumpAndSettle();
    expect(find.text('final wording', findRichText: true), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a reply whose parent is outside the window still fetches and '
      'shows it', (tester) async {
    final _GatedMessageRepository repository = _GatedMessageRepository();
    final reply = _replyTo('parent-1');

    await tester.pumpWidget(
      _buildTestApp(
        chatViewModel: _TestChatViewModel(_chatState(messages: [reply])),
        repository: repository,
        child: InlineReplyPreview(message: reply),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.requestedIds, <String>['parent-1']);

    repository.parent.complete(
      _message(
        id: 'parent-1',
        authorId: '1001',
        authorName: 'Sample User',
        content: 'from the archive',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('from the archive', findRichText: true), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a reply to a blocked author hides the parent and ignores taps', (
    tester,
  ) async {
    final parent = _message(
      id: 'parent-1',
      authorId: '1001',
      authorName: 'Blocked User',
      content: 'blocked words',
    );
    final reply = _replyTo('parent-1');
    final _TestChatViewModel viewModel = _TestChatViewModel(
      _chatState(messages: [parent, reply]),
    );

    await tester.pumpWidget(
      _buildTestApp(
        chatViewModel: viewModel,
        blockedUserIds: const <String>{'1001'},
        child: InlineReplyPreview(message: reply),
      ),
    );

    expect(
      find.text('Reply hidden because the original author is blocked.'),
      findsOneWidget,
    );
    expect(find.text('blocked words', findRichText: true), findsNothing);

    await tester.tap(find.byType(InlineReplyPreview));
    await tester.pump();
    expect(viewModel.repliedJumps, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('a blocked parent outside the window stays hidden', (
    tester,
  ) async {
    final _GatedMessageRepository repository = _GatedMessageRepository();
    final reply = _replyTo('parent-1');
    final _TestChatViewModel viewModel = _TestChatViewModel(
      _chatState(messages: [reply]),
    );

    await tester.pumpWidget(
      _buildTestApp(
        chatViewModel: viewModel,
        repository: repository,
        blockedUserIds: const <String>{'1001'},
        child: InlineReplyPreview(message: reply),
      ),
    );
    await tester.pumpAndSettle();
    repository.parent.complete(
      _message(
        id: 'parent-1',
        authorId: '1001',
        authorName: 'Blocked User',
        content: 'blocked words',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Reply hidden because the original author is blocked.'),
      findsOneWidget,
    );
    expect(find.text('blocked words', findRichText: true), findsNothing);

    await tester.tap(find.byType(InlineReplyPreview));
    await tester.pump();
    expect(viewModel.repliedJumps, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Widget _buildTestApp({
  required Widget child,
  ChatViewState? chatState,
  _TestChatViewModel? chatViewModel,
  MessageRepository? repository,
  Set<String> blockedUserIds = const <String>{},
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [
      if (chatViewModel != null)
        chatViewModelProvider.overrideWith(() => chatViewModel)
      else
        chatViewModelProvider.overrideWithValue(chatState!),
      activeGuildIdProvider.overrideWithValue(null),
      currentUserIdProvider.overrideWithValue(null),
      starDatabaseProvider.overrideWithValue(_database),
      if (repository != null)
        messageRepositoryProvider.overrideWithValue(repository),
      channelCollapseContextProvider.overrideWithValue(
        ChannelCollapseContext(
          treatSpam: true,
          currentUserId: null,
          blockedUserIds: blockedUserIds,
          isUserMarkedAsSpammer: (_, _) => false,
        ),
      ),
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
  );
}

class _TestChatViewModel extends ChatViewModel {
  _TestChatViewModel(this._initialState);

  final ChatViewState _initialState;
  final List<String> repliedJumps = <String>[];

  @override
  Future<void> goToRepliedMessage({
    required String channelId,
    required String messageId,
  }) async {
    repliedJumps.add(messageId);
  }

  void write(List<Message> messages, MessagesOrigin origin) {
    state = state.copyWith(write: (messages: messages, origin: origin));
  }

  @override
  ChatViewState build() => _initialState;
}

class _GatedMessageRepository extends Fake implements MessageRepository {
  final List<String> requestedIds = <String>[];
  final Completer<Message> parent = Completer<Message>();

  @override
  Future<Message> fetchMessage({
    required String channelId,
    required String messageId,
  }) {
    requestedIds.add(messageId);
    return parent.future;
  }
}

Message _replyTo(String parentId) => _message(
  id: 'reply-1',
  authorId: '1002',
  authorName: 'August',
  type: messageTypeReply,
  messageReference: MessageReference(
    channelId: 'channel-1',
    messageId: parentId,
    type: MessageReferenceType.valueDefault,
  ),
);

ChatViewState _chatState({required List<Message> messages}) {
  return ChatViewState(
    channelId: 'channel-1',
    messages: messages,
    replyingTo: null,
    replyMentioning: false,
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

Message _message({
  required String id,
  required String authorId,
  required String authorName,
  bool authorIsBot = false,
  int type = messageTypeDefault,
  List<String> mentionedUserIds = const [],
  MessageReference? messageReference,
  String content = 'hello',
}) {
  return Message(
    id: id,
    channelId: 'channel-1',
    authorId: authorId,
    authorName: authorName,
    authorIsBot: authorIsBot,
    content: content,
    timestamp: DateTime.utc(2026),
    type: type,
    mentionedUserIds: mentionedUserIds,
    replyToId: messageReference?.messageId,
    messageReference: messageReference,
  );
}
