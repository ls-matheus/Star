import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/domain/channel_permission_overwrite_update.dart';
import 'package:star_app/features/channels/presentation/channel_settings/widgets/channel_add_override_popout.dart';
import 'package:star_app/features/channels/presentation/channel_settings/widgets/channel_overwrite_list_item.dart';
import 'package:star_app/features/channels/presentation/channel_settings/widgets/channel_permissions_sync_banner.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/popout/star_popout.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ChannelPermissionsOverridesView extends StatelessWidget {
  const ChannelPermissionsOverridesView({
    required this.guildId,
    required this.entries,
    required this.selectedId,
    required this.rolesById,
    required this.canEdit,
    required this.onSelected,
    required this.onAddOverride,
    this.parentChannel,
    this.isSyncedWithParent,
    this.onSyncWithParent,
    this.scrollController,
    super.key,
  });

  final String guildId;
  final List<ChannelPermissionOverwriteEntry> entries;
  final String? selectedId;
  final Map<String, db.Role> rolesById;
  final bool canEdit;
  final ValueChanged<String> onSelected;
  final void Function(String id, int type, String name) onAddOverride;
  final Channel? parentChannel;
  final bool? isSyncedWithParent;
  final VoidCallback? onSyncWithParent;
  final ScrollController? scrollController;

  Set<String> get _existingOverwriteIds =>
      entries.map((ChannelPermissionOverwriteEntry entry) => entry.id).toSet();

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    final double horizontalPadding = isMobile ? context.layout.s4 : 8;
    final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
      horizontalPadding,
      isMobile ? context.layout.s4 : 8,
      horizontalPadding,
      context.layout.s20,
    );
    return CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        if (isSyncedWithParent != null && parentChannel != null)
          SliverPadding(
            padding: contentPadding.copyWith(bottom: context.layout.s4),
            sliver: SliverToBoxAdapter(
              child: ChannelPermissionsSyncBanner(
                isSyncedWithParent: isSyncedWithParent!,
                parentChannel: parentChannel!,
                canEdit: canEdit,
                onSyncWithParent: onSyncWithParent ?? () {},
              ),
            ),
          ),
        SliverPadding(
          padding: contentPadding.copyWith(
            top: isSyncedWithParent != null ? 0 : contentPadding.top,
            bottom: context.layout.s2,
          ),
          sliver: SliverToBoxAdapter(
            child: _buildAccessOverridesHeader(context, l10n, isMobile),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            contentPadding.bottom,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final ChannelPermissionOverwriteEntry entry = entries[index];
              final bool isSelected = entry.id == selectedId;
              final db.Role? role = entry.type == 0
                  ? rolesById[entry.id]
                  : null;
              return Padding(
                padding: EdgeInsets.only(bottom: isMobile ? 8 : 0),
                child: ChannelOverwriteListItem(
                  entry: entry,
                  isSelected: isSelected,
                  roleColor: role?.color,
                  showChevron: isMobile,
                  useMobileTileStyle: isMobile,
                  onTap: () => onSelected(entry.id),
                ),
              );
            }, childCount: entries.length),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessOverridesHeader(
    BuildContext context,
    StarLocalizations l10n,
    bool isMobile,
  ) {
    final Widget title = Text(
      l10n.channelSettingsPermissionsAccessOverrides,
      style: isMobile
          ? context.textStyles.heading
          : context.textStyles.categoryName,
      maxLines: isMobile ? 2 : 1,
      overflow: TextOverflow.ellipsis,
    );
    final Widget addOverrideControl = _buildAddOverrideControl(
      context,
      l10n,
      isMobile,
    );
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          title,
          SizedBox(height: context.layout.s2),
          addOverrideControl,
        ],
      );
    }
    return Row(
      children: <Widget>[
        Expanded(child: title),
        SizedBox(width: context.layout.s2),
        addOverrideControl,
      ],
    );
  }

  Widget _buildAddOverrideControl(
    BuildContext context,
    StarLocalizations l10n,
    bool isMobile,
  ) {
    if (isMobile) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: _addOverrideButton(
          context,
          l10n,
          onPressed: canEdit
              ? () => ChannelAddOverrideSheet.show(
                  context,
                  guildId: guildId,
                  rolesById: rolesById,
                  existingOverwriteIds: _existingOverwriteIds,
                  onSelect: onAddOverride,
                )
              : null,
        ),
      );
    }
    return StarPopout(
      anchorBuilder: (BuildContext context, VoidCallback toggle) {
        return _addOverrideButton(
          context,
          l10n,
          onPressed: canEdit ? toggle : null,
        );
      },
      contentBuilder: (BuildContext context, VoidCallback close) {
        return ChannelAddOverridePickerContent(
          guildId: guildId,
          rolesById: rolesById,
          existingOverwriteIds: _existingOverwriteIds,
          width: MediaQuery.sizeOf(context).width - 16,
          onSelect: onAddOverride,
          onClose: close,
        );
      },
    );
  }

  Widget _addOverrideButton(
    BuildContext context,
    StarLocalizations l10n, {
    required VoidCallback? onPressed,
  }) {
    return StarButton.secondary(
      onPressed: onPressed,
      label: l10n.channelSettingsPermissionsAddOverride,
      size: StarButtonSize.small,
      icon: PhosphorIconsBold.plus,
      fitContent: true,
    );
  }
}
