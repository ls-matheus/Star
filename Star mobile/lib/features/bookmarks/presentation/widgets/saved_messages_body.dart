import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/api/dio_error_message.dart';
import 'package:star_app/core/database/star_database.dart' as drift_db;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/router/navigate_to_content.dart';
import 'package:star_app/core/router/route_names.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/bookmarks/domain/saved_messages.dart';
import 'package:star_app/features/bookmarks/presentation/widgets/saved_messages_empty_state.dart';
import 'package:star_app/features/bookmarks/presentation/widgets/saved_messages_end_footer.dart';
import 'package:star_app/features/bookmarks/providers/saved_messages_provider.dart';
import 'package:star_app/features/bookmarks/utils/saved_message_actions.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/notifications/data/mention_header_loader.dart';
import 'package:star_app/features/notifications/domain/mention_header.dart';
import 'package:star_app/features/notifications/presentation/widgets/mention_inbox_card.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/refresh/star_refresh_scroll_view.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

const double _kLoadMoreScrollThreshold = 0.8;

class SavedMessagesBody extends ConsumerStatefulWidget {
  const SavedMessagesBody({
    super.key,
    this.scrollController,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 12),
    this.onClose,
  });

  final ScrollController? scrollController;
  final EdgeInsets padding;
  final VoidCallback? onClose;

  @override
  ConsumerState<SavedMessagesBody> createState() => _SavedMessagesBodyState();
}

class _SavedMessagesBodyState extends ConsumerState<SavedMessagesBody> {
  final Map<String, MentionHeader> _headerByChannelId =
      <String, MentionHeader>{};
  final Map<String, String> _guildIdPreviewByChannelId = <String, String>{};

  @override
  void initState() {
    super.initState();
    ref.listenManual<SavedMessagesState>(savedMessagesProvider, (
      SavedMessagesState? previous,
      SavedMessagesState next,
    ) {
      if (!next.fetched && !next.isLoadingMore) {
        _scheduleFetch();
      }
      unawaited(_loadHeaders(next));
    }, fireImmediately: true);
  }

  void _scheduleFetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final SavedMessagesState list = ref.read(savedMessagesProvider);
      if (list.fetched || list.isLoadingMore) {
        return;
      }
      unawaited(ref.read(savedMessagesProvider.notifier).refresh());
    });
  }

  Future<void> _refresh() async {
    await ref.read(savedMessagesProvider.notifier).refresh();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) {
      return false;
    }
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= 0) {
      return false;
    }
    final SavedMessagesState list = ref.read(savedMessagesProvider);
    if (!list.hasMore || list.isLoadingMore) {
      return false;
    }
    final double height = metrics.maxScrollExtent + metrics.viewportDimension;
    final double progress =
        (metrics.pixels + metrics.viewportDimension) / height;
    if (progress <= _kLoadMoreScrollThreshold) {
      return false;
    }
    unawaited(ref.read(savedMessagesProvider.notifier).loadMore());
    return false;
  }

  Future<void> _loadHeaders(SavedMessagesState list) async {
    final Set<String> channelIds = <String>{
      for (final Message message in list.messages) message.channelId,
      for (final SavedMessageMissingEntry entry in list.missing)
        if (entry.channelId.isNotEmpty) entry.channelId,
    };
    final int headerCount = _headerByChannelId.length;
    _headerByChannelId.removeWhere(
      (String key, MentionHeader _) => !channelIds.contains(key),
    );
    _guildIdPreviewByChannelId.removeWhere(
      (String key, String _) => !channelIds.contains(key),
    );
    bool changed = _headerByChannelId.length != headerCount;
    final drift_db.StarDatabase db = ref.read(starDatabaseProvider);
    for (final String channelId in channelIds) {
      if (_headerByChannelId.containsKey(channelId) || !mounted) {
        continue;
      }
      final MentionHeaderResult result = await loadMentionHeaderForChannelId(
        db,
        channelId,
      );
      if (!mounted) {
        return;
      }
      _headerByChannelId[channelId] = result.header;
      _guildIdPreviewByChannelId[channelId] = result.guildIdForPreview;
      changed = true;
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  Future<void> _removeBookmark(String messageId) async {
    await unsaveMessageBookmark(
      ref: ref,
      l10n: StarLocalizations.of(context),
      messageId: messageId,
    );
  }

  Future<void> _jumpToMessage(Message message) async {
    final ProviderContainer container = ref.container;
    final drift_db.StarDatabase db = container.read(starDatabaseProvider);
    final drift_db.Channel? channel = await db.channelDao.getChannelById(
      message.channelId,
    );
    if (!mounted) {
      return;
    }
    widget.onClose?.call();
    final String path = channel == null
        ? RoutePaths.dmChannelMessage(message.channelId, message.id)
        : RoutePaths.guildChannelMessage(
            channel.guildId,
            message.channelId,
            message.id,
          );
    navigateToContentViaContainer(container, path);
  }

  @override
  Widget build(BuildContext context) {
    final StarColorTheme colors = context.colors;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final SavedMessagesState list = ref.watch(savedMessagesProvider);
    return Padding(
      padding: widget.padding,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: _buildContent(list, colors, l10n),
      ),
    );
  }

  Widget _buildContent(
    SavedMessagesState list,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    if (!list.fetched) {
      return _buildLoading(colors);
    }
    if (list.lastError != null && list.isEmpty) {
      return _buildError(list.lastError!, l10n);
    }
    if (list.isEmpty) {
      return StarRefreshScrollView(
        controller: widget.scrollController,
        onRefresh: _refresh,
        slivers: <Widget>[
          const SliverFillRemaining(
            hasScrollBody: false,
            child: SavedMessagesEmptyState(),
          ),
          _bottomInsetSliver(context),
        ],
      );
    }
    return StarRefreshScrollView(
      controller: widget.scrollController,
      onRefresh: _refresh,
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate(<Widget>[
            for (final SavedMessageMissingEntry entry in list.missing)
              _card(
                messageId: entry.messageId,
                channelId: entry.channelId,
                message: null,
                l10n: l10n,
              ),
            for (final Message message in list.messages)
              _card(
                messageId: message.id,
                channelId: message.channelId,
                message: message,
                l10n: l10n,
              ),
          ]),
        ),
        if (list.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: StarLoadingSpinner()),
            ),
          ),
        if (!list.hasMore && !list.isLoadingMore)
          const SliverToBoxAdapter(child: SavedMessagesEndFooter()),
        _bottomInsetSliver(context),
      ],
    );
  }

  Widget _card({
    required String messageId,
    required String channelId,
    required Message? message,
    required StarLocalizations l10n,
  }) {
    return MentionInboxCard(
      messageId: messageId,
      message: message,
      header: channelId.isEmpty ? null : _headerByChannelId[channelId],
      previewGuildId: _guildIdPreviewByChannelId[channelId],
      title: MentionInboxCardTitle.plain,
      isUnread: true,
      removeLabel: l10n.savedMessagesRemoveTooltip,
      onJump: (Message msg) => unawaited(_jumpToMessage(msg)),
      onRemove: (String id) => unawaited(_removeBookmark(id)),
    );
  }

  Widget _bottomInsetSliver(BuildContext context) {
    final double bottom = StarBottomSheet.scrollBottomPaddingOf(context);
    if (bottom <= 0) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverPadding(
      padding: EdgeInsets.only(bottom: bottom),
      sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildLoading(StarColorTheme colors) {
    return StarRefreshScrollView(
      controller: widget.scrollController,
      onRefresh: _refresh,
      slivers: <Widget>[
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: StarLoadingSpinner()),
        ),
        _bottomInsetSliver(context),
      ],
    );
  }

  Widget _buildError(Object error, StarLocalizations l10n) {
    return StarRefreshScrollView(
      controller: widget.scrollController,
      onRefresh: _refresh,
      slivers: <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    userFacingErrorMessage(error, l10n.networkErrorMessage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.statusDanger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => unawaited(_refresh()),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        ),
        _bottomInsetSliver(context),
      ],
    );
  }
}
