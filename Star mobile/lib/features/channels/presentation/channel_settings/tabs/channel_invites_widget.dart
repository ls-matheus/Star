import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/well_known_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/presentation/channel_settings/widgets/channel_settings_status_slate.dart';
import 'package:star_app/features/channels/presentation/modals/show_channel_invite_modal.dart';
import 'package:star_app/features/channels/providers/channel_invites_provider.dart';
import 'package:star_app/features/channels/utils/channel_invite_capability.dart';
import 'package:star_app/features/settings/domain/guild/guild_invite_entry.dart';
import 'package:star_app/features/settings/domain/guild/guild_invites_state.dart';
import 'package:star_app/features/settings/presentation/widgets/guild/invites/guild_disable_invites_button.dart';
import 'package:star_app/features/settings/presentation/widgets/guild/invites/guild_invites_list_item.dart';
import 'package:star_app/features/settings/utils/guild/guild_invites_utils.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/bottom_sheet/star_confirm_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/checkbox/star_checkbox.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_app/shared/utils/clipboard_utils.dart';

class ChannelInvitesWidget extends ConsumerStatefulWidget {
  const ChannelInvitesWidget({
    required this.channel,
    required this.permissions,
    this.scrollController,
    super.key,
  });

  final Channel channel;
  final int permissions;
  final ScrollController? scrollController;

  @override
  ConsumerState<ChannelInvitesWidget> createState() =>
      _ChannelInvitesWidgetState();
}

class _ChannelInvitesWidgetState extends ConsumerState<ChannelInvitesWidget> {
  bool _showCreatedDate = false;
  ScrollController? _ownedScrollController;

  ScrollController get _scrollController =>
      widget.scrollController ?? _ownedScrollController!;

  bool get _canInvite => resolveChannelInviteCapability(
    permissionBits: widget.permissions,
    channel: widget.channel,
    guildId: widget.channel.guildId,
  ).canInvite;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    super.dispose();
  }

  Future<void> _copyInviteUrl(String inviteUrl) async {
    await copyToClipboard(context: context, value: inviteUrl);
  }

  Future<void> _copyInviteCode(String code) async {
    await copyToClipboard(context: context, value: code);
  }

  Future<void> _revokeInvite(GuildInviteEntry invite) async {
    try {
      await ref
          .read(channelInvitesProvider(widget.channel.id).notifier)
          .revokeInvite(invite.code);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      await showApiError(context, ApiErrorAction.revokeInvite, error);
    }
  }

  Future<void> _confirmRevoke(GuildInviteEntry invite) async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool? confirmed = await StarConfirmSheet.show(
      context,
      title: l10n.channelSettingsDeleteInvite,
      description: l10n.channelSettingsDeleteInviteConfirm,
      confirmLabel: l10n.channelSettingsDeleteInvite,
      isDanger: true,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _revokeInvite(invite);
  }

  Future<void> _showMobileInviteActions(
    GuildInviteEntry invite,
    String inviteUrl,
  ) async {
    final StarLocalizations l10n = StarLocalizations.of(context);
    await StarBottomSheet.show<void>(
      context,
      title: invite.code,
      variant: StarBottomSheetVariant.menu,
      builder: (BuildContext sheetContext, VoidCallback close) {
        return StarBottomSheetContent(
          child: StarMenuGroup(
            children: <Widget>[
              StarBottomSheetMenuItem(
                label: l10n.channelSettingsCopyInviteCode,
                icon: PhosphorIconsBold.copy,
                onTap: () {
                  close();
                  unawaited(_copyInviteCode(invite.code));
                },
              ),
              StarBottomSheetMenuItem(
                label: l10n.channelSettingsCopyInviteUrl,
                icon: PhosphorIconsBold.link,
                onTap: () {
                  close();
                  unawaited(_copyInviteUrl(inviteUrl));
                },
              ),
              StarBottomSheetMenuItem(
                label: l10n.channelSettingsDeleteInvite,
                icon: PhosphorIconsBold.trash,
                isDanger: true,
                onTap: () {
                  close();
                  unawaited(_confirmRevoke(invite));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createInvite() async {
    await showChannelInviteModal(
      context,
      ref,
      channelId: widget.channel.id,
      channelName: widget.channel.name,
      guildId: widget.channel.guildId,
      useVanityUrl: false,
    );
    if (!mounted) {
      return;
    }
    await ref.read(channelInvitesProvider(widget.channel.id).notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    final AsyncValue<GuildInvitesState> invitesAsync = ref.watch(
      channelInvitesProvider(widget.channel.id),
    );
    return invitesAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(context, l10n),
          _buildButtonGroup(context, l10n, isLoading: true),
          const Expanded(child: Center(child: StarLoadingSpinner())),
        ],
      ),
      error: (Object error, StackTrace stackTrace) => _buildShell(
        context,
        l10n: l10n,
        isLoading: false,
        child: ChannelSettingsStatusSlate(
          icon: PhosphorIconsFill.warningOctagon,
          title: l10n.guildSettingsInvitesLoadFailedTitle,
          description: l10n.channelSettingsInvitesLoadFailedDescription,
          actionLabel: l10n.guildSettingsInvitesTryAgain,
          onAction: () =>
              ref.invalidate(channelInvitesProvider(widget.channel.id)),
        ),
      ),
      data: (GuildInvitesState state) {
        if (state.loadStatus == GuildInvitesLoadStatus.error) {
          return _buildShell(
            context,
            l10n: l10n,
            isLoading: false,
            child: ChannelSettingsStatusSlate(
              icon: PhosphorIconsFill.warningOctagon,
              title: l10n.guildSettingsInvitesLoadFailedTitle,
              description: l10n.channelSettingsInvitesLoadFailedDescription,
              actionLabel: l10n.guildSettingsInvitesTryAgain,
              onAction: () =>
                  ref.invalidate(channelInvitesProvider(widget.channel.id)),
            ),
          );
        }
        if (state.invites.isEmpty) {
          return _buildShell(
            context,
            l10n: l10n,
            isLoading: false,
            child: ChannelSettingsStatusSlate(
              icon: PhosphorIconsFill.userPlus,
              title: l10n.channelSettingsInvitesEmpty,
              description: l10n.channelSettingsInvitesEmptyDescription,
              actionLabel: _canInvite
                  ? l10n.channelSettingsInvitesCreate
                  : null,
              onAction: _canInvite ? () => unawaited(_createInvite()) : null,
            ),
          );
        }
        return CustomScrollView(
          controller: _scrollController,
          slivers: <Widget>[
            SliverToBoxAdapter(child: _buildHeader(context, l10n)),
            SliverToBoxAdapter(child: _buildButtonGroup(context, l10n)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.layout.s4,
                  0,
                  context.layout.s4,
                  context.layout.s4,
                ),
                child: StarCheckbox(
                  value: _showCreatedDate,
                  label: l10n.guildSettingsInvitesShowCreatedDate,
                  onChanged: (bool? value) {
                    setState(() => _showCreatedDate = value ?? false);
                  },
                ),
              ),
            ),
            if (!isMobile)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  context.layout.s4,
                  0,
                  context.layout.s4,
                  context.layout.s2,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildDesktopListHeader(context, l10n),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                context.layout.s4,
                0,
                context.layout.s4,
                context.layout.s4,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  final GuildInviteEntry invite = state.invites[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.layout.s2),
                    child: _buildInviteItem(
                      context,
                      l10n: l10n,
                      invite: invite,
                      isMobile: isMobile,
                    ),
                  );
                }, childCount: state.invites.length),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required StarLocalizations l10n,
    required bool isLoading,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildHeader(context, l10n),
        _buildButtonGroup(context, l10n, isLoading: isLoading),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, StarLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.s4,
        context.layout.s4,
        context.layout.s4,
        context.layout.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.channelSettingsTabInvites,
            style: context.textStyles.heading.copyWith(
              fontSize: 18,
              color: context.colors.textChat,
            ),
          ),
          SizedBox(height: context.layout.s1),
          Text(
            l10n.channelSettingsInvitesDescription,
            style: context.textStyles.bodyMedium.copyWith(
              color: context.colors.textPrimaryMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGroup(
    BuildContext context,
    StarLocalizations l10n, {
    bool isLoading = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.s4,
        0,
        context.layout.s4,
        context.layout.s4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StarButton.primary(
            onPressed: !_canInvite || isLoading
                ? null
                : () => unawaited(_createInvite()),
            label: l10n.channelSettingsInvitesCreate,
            size: StarButtonSize.small,
            fitContent: true,
          ),
          SizedBox(width: context.layout.s2),
          Expanded(
            child: GuildDisableInvitesButton(
              guildId: widget.channel.guildId,
              embedded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopListHeader(
    BuildContext context,
    StarLocalizations l10n,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.s3,
        0,
        context.layout.s3,
        context.layout.s2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 24,
            child: Text(
              l10n.guildSettingsInvitesTableInviter,
              style: context.textStyles.categoryName,
            ),
          ),
          SizedBox(width: context.layout.s2),
          Expanded(
            flex: 22,
            child: Text(
              l10n.guildSettingsInvitesTableCode,
              style: context.textStyles.categoryName,
            ),
          ),
          SizedBox(width: context.layout.s2),
          Expanded(
            flex: 10,
            child: Text(
              l10n.guildSettingsInvitesTableUses,
              style: context.textStyles.categoryName,
            ),
          ),
          SizedBox(width: context.layout.s2),
          Expanded(
            flex: 18,
            child: Text(
              _showCreatedDate
                  ? l10n.guildSettingsInvitesTableCreated
                  : l10n.guildSettingsInvitesTableExpires,
              style: context.textStyles.categoryName,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteItem(
    BuildContext context, {
    required StarLocalizations l10n,
    required GuildInviteEntry invite,
    required bool isMobile,
  }) {
    final String inviteBase = ref.read(instanceInviteBaseUrlProvider);
    final String inviteUrl = GuildInvitesUtils.buildInviteUrl(
      inviteBaseUrl: inviteBase,
      code: invite.code,
    );
    return GuildInvitesListItem(
      entry: invite,
      l10n: l10n,
      showCreatedDate: _showCreatedDate,
      isMobile: isMobile,
      showChannel: false,
      categoryName: null,
      onCopy: () => unawaited(_copyInviteUrl(inviteUrl)),
      onRevoke: () => unawaited(_confirmRevoke(invite)),
      onTap: isMobile
          ? () => unawaited(_showMobileInviteActions(invite, inviteUrl))
          : null,
    );
  }
}
