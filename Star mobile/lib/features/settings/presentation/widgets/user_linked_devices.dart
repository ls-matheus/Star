import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/providers/current_auth_session_provider.dart';
import 'package:star_app/features/settings/presentation/sheets/device_details_sheet.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/linked_devices_view_model.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';
import 'package:star_app/shared/utils/relative_time.dart';
import 'package:star_dart/export.dart';

class UserLinkedDevices extends ConsumerStatefulWidget {
  const UserLinkedDevices({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserLinkedDevices> createState() => _UserLinkedDevicesState();
}

class _UserLinkedDevicesState extends ConsumerState<UserLinkedDevices> {
  bool _selectionMode = false;
  final Set<String> _selected = {};
  int _lastToggledIndex = -1;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(linkedDevicesViewModelProvider);
    final currentIdHash = ref.watch(currentAuthSessionIdHashProvider);
    final colors = context.colors;
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);

    AuthSessionResponse? current;
    if (currentIdHash != null) {
      for (final session in state.sessions) {
        if (session.idHash == currentIdHash) {
          current = session;
          break;
        }
      }
    }

    final Widget body;
    if (state.isLoading) {
      body = const Center(child: StarLoadingSpinner());
    } else if (state.error != null || current == null) {
      body = _buildLoadError(context, colors, layout, l10n);
    } else {
      final others = state.sessions.where((s) => s != current).toList();
      body = _buildContent(context, current, others, colors, layout, l10n);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0.0;
        return SingleChildScrollView(
          controller: widget.scrollController,
          padding: settingsScrollPadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: body,
          ),
        );
      },
    );
  }

  Widget _buildLoadError(
    BuildContext context,
    StarColorTheme colors,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIconsFill.networkSlash,
            size: 48,
            color: colors.textPrimaryMuted,
          ),
          SizedBox(height: layout.s3),
          Text(
            l10n.linkedDevicesLoadErrorTitle,
            style: context.textStyles.heading.copyWith(
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: layout.s1),
          Text(
            l10n.linkedDevicesLoadErrorDescription,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: layout.s4),
          StarButton.primary(
            label: l10n.retry,
            onPressedAsync: ref
                .read(linkedDevicesViewModelProvider.notifier)
                .load,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AuthSessionResponse current,
    List<AuthSessionResponse> others,
    StarColorTheme colors,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    final state = ref.watch(linkedDevicesViewModelProvider);
    return Padding(
      padding: EdgeInsets.only(top: layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarSettingsSection(
            title: l10n.linkedDevicesTitle,
            description: l10n.linkedDevicesDescription,
            isFirst: true,
            children: [
              _buildCurrentGroup(current, colors, layout, l10n),
              if (others.isNotEmpty)
                _buildOthersGroup(others, state, colors, layout, l10n),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentGroup(
    AuthSessionResponse current,
    StarColorTheme colors,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StarSubsectionLabel(l10n.linkedDevicesCurrentDevice),
        SizedBox(height: layout.s2),
        _AuthSessionCard(
          session: current,
          isCurrent: true,
          selectionMode: _selectionMode,
          isSelected: false,
          isRevoking: false,
          onViewDetails: _selectionMode
              ? null
              : () => _showDeviceDetails(current, isCurrent: true),
        ),
      ],
    );
  }

  Widget _buildOthersGroup(
    List<AuthSessionResponse> others,
    LinkedDevicesViewState state,
    StarColorTheme colors,
    StarLayoutTheme layout,
    StarLocalizations l10n,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: layout.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StarSubsectionLabel(l10n.linkedDevicesOtherDevices),
              ),
              if (others.length > 1) _buildActionButtons(others, l10n, colors),
            ],
          ),
          SizedBox(height: layout.s2),
          for (int i = 0; i < others.length; i++) ...[
            _AuthSessionCard(
              session: others[i],
              isCurrent: false,
              selectionMode: _selectionMode,
              isSelected: _selected.contains(others[i].idHash),
              isRevoking: state.revokingIds.contains(others[i].idHash),
              onTap: _selectionMode ? () => _toggleSelection(others, i) : null,
              onViewDetails: _selectionMode
                  ? null
                  : () => _showDeviceDetails(others[i], isCurrent: false),
              onRevoke: _selectionMode
                  ? null
                  : () => _handleSingleRevoke(others[i], l10n),
            ),
            if (i < others.length - 1) SizedBox(height: layout.s3),
          ],
          if (others.length > 1 ||
              (_selectionMode && _selected.isNotEmpty)) ...[
            SizedBox(height: layout.s4),
            _buildBulkButton(others, l10n),
            SizedBox(height: layout.s2),
            Text(
              l10n.linkedDevicesLogoutDisclaimer,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    List<AuthSessionResponse> others,
    StarLocalizations l10n,
    StarColorTheme colors,
  ) {
    return Row(
      children: [
        StarTooltip(
          message: _selectionMode
              ? l10n.linkedDevicesExitSelection
              : l10n.linkedDevicesEnterSelection,
          child: _iconButton(
            icon: _selectionMode
                ? PhosphorIconsBold.x
                : PhosphorIconsFill.checkSquare,
            semanticLabel: _selectionMode
                ? l10n.linkedDevicesExitSelection
                : l10n.linkedDevicesEnterSelection,
            onTap: () => setState(() {
              _selectionMode = !_selectionMode;
              if (!_selectionMode) {
                _selected.clear();
                _lastToggledIndex = -1;
              }
            }),
            colors: colors,
          ),
        ),
        if (_selectionMode) ...[
          const SizedBox(width: 4),
          StarTooltip(
            message: _selected.length == others.length
                ? l10n.linkedDevicesClearSelection
                : l10n.linkedDevicesSelectAll,
            child: _iconButton(
              icon: _selected.length == others.length
                  ? PhosphorIconsBold.square
                  : PhosphorIconsFill.checkSquare,
              semanticLabel: _selected.length == others.length
                  ? l10n.linkedDevicesClearSelection
                  : l10n.linkedDevicesSelectAll,
              onTap: () => setState(() {
                if (_selected.length == others.length) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(others.map((s) => s.idHash));
                }
              }),
              colors: colors,
            ),
          ),
        ],
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String semanticLabel,
    required VoidCallback onTap,
    required StarColorTheme colors,
  }) {
    return StarTappable(
      key: ValueKey(semanticLabel),
      onTap: onTap,
      semanticLabel: semanticLabel,
      excludeChildSemantics: true,
      builder: (context, states) => Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: states.contains(WidgetState.hovered)
              ? colors.backgroundModifierHover
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: PhosphorIcon(icon, size: 18, color: colors.textTertiary),
      ),
    );
  }

  Widget _buildBulkButton(
    List<AuthSessionResponse> others,
    StarLocalizations l10n,
  ) {
    final selectedCount = _selectionMode ? _selected.length : 0;
    final label = selectedCount > 0
        ? l10n.linkedDevicesSignOutN(selectedCount)
        : l10n.linkedDevicesSignOutAll;

    return SizedBox(
      width: double.infinity,
      child: StarButton.dangerSecondary(
        label: label,
        onPressedAsync: () => _handleBulkRevoke(others, l10n),
      ),
    );
  }

  void _toggleSelection(List<AuthSessionResponse> others, int index) {
    final id = others[index].idHash;
    final shiftHeld =
        HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.shiftLeft,
        ) ||
        HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.shiftRight,
        );

    setState(() {
      if (shiftHeld && _lastToggledIndex != -1) {
        final start = _lastToggledIndex < index ? _lastToggledIndex : index;
        final end = _lastToggledIndex < index ? index : _lastToggledIndex;
        final shouldAdd = !_selected.contains(id);
        for (var i = start; i <= end; i++) {
          if (shouldAdd) {
            _selected.add(others[i].idHash);
          } else {
            _selected.remove(others[i].idHash);
          }
        }
      } else {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      }
      _lastToggledIndex = index;
    });
  }

  void _showDeviceDetails(
    AuthSessionResponse session, {
    required bool isCurrent,
  }) {
    unawaited(
      DeviceDetailsSheet.show(context, session: session, isCurrent: isCurrent),
    );
  }

  Future<void> _handleSingleRevoke(
    AuthSessionResponse session,
    StarLocalizations l10n,
  ) async {
    await _showRevokeSheet(
      ids: [session.idHash],
      title: l10n.linkedDevicesSignOutSheetTitle(1),
      description: l10n.linkedDevicesSignOutSheetDescription(1),
      l10n: l10n,
    );
  }

  Future<void> _handleBulkRevoke(
    List<AuthSessionResponse> others,
    StarLocalizations l10n,
  ) async {
    final selectedCount = _selectionMode ? _selected.length : 0;
    final ids = selectedCount > 0
        ? _selected.toList()
        : others.map((s) => s.idHash).toList();

    if (selectedCount > 0) {
      await _showRevokeSheet(
        ids: ids,
        title: l10n.linkedDevicesSignOutSheetTitle(selectedCount),
        description: l10n.linkedDevicesSignOutSheetDescription(selectedCount),
        l10n: l10n,
      );
    } else {
      await _showRevokeSheet(
        ids: ids,
        title: l10n.linkedDevicesSignOutAllSheetTitle,
        description: l10n.linkedDevicesSignOutAllSheetDescription,
        l10n: l10n,
      );
    }
  }

  Future<void> _showRevokeSheet({
    required List<String> ids,
    required String title,
    required String description,
    required StarLocalizations l10n,
  }) async {
    final layout = context.layout;
    final colors = context.colors;

    await StarBottomSheet.show<void>(
      context,
      title: title,
      useRootNavigator: true,
      builder: (sheetContext, close) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                description,
                style: sheetContext.textStyles.bodySmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: layout.s4),
              StarButton.dangerPrimary(
                label: l10n.linkedDevicesSignOutConfirm,
                onPressedAsync: () async {
                  final success = await _performRevoke(ids, l10n);
                  if (success && sheetContext.mounted) {
                    close();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _performRevoke(
    List<String> ids,
    StarLocalizations l10n,
  ) async {
    try {
      await ref.read(linkedDevicesViewModelProvider.notifier).logout(ids);
      if (!mounted) {
        return false;
      }
      setState(() {
        _selectionMode = false;
        _selected.clear();
        _lastToggledIndex = -1;
      });
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.linkedDevicesRevokeSuccess(ids.length),
              variant: StarToastVariant.success,
            ),
          );
      return true;
    } on Object catch (error) {
      if (!mounted) {
        return false;
      }
      await showApiError(context, ApiErrorAction.revokeSessions, error);
      return false;
    }
  }
}

class _AuthSessionCard extends StatelessWidget {
  const _AuthSessionCard({
    required this.session,
    required this.isCurrent,
    required this.selectionMode,
    required this.isSelected,
    required this.isRevoking,
    this.onTap,
    this.onViewDetails,
    this.onRevoke,
  });

  final AuthSessionResponse session;
  final bool isCurrent;
  final bool selectionMode;
  final bool isSelected;
  final bool isRevoking;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    final l10n = StarLocalizations.of(context);
    final card = Container(
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border.all(color: colors.borderColor),
        borderRadius: layout.radiusLg,
      ),
      padding: EdgeInsets.all(layout.s4),
      child: Row(
        children: [
          _iconBubble(colors),
          SizedBox(width: layout.s3),
          Expanded(child: _info(context, colors)),
          SizedBox(width: layout.s2),
          _trailing(context, colors, l10n),
        ],
      ),
    );

    if (selectionMode && !isCurrent && onTap != null) {
      return StarTappable(onTap: onTap, builder: (_, _) => card);
    }
    return card;
  }

  Widget _iconBubble(StarColorTheme colors) {
    final isMobile =
        session.clientInfo?.device ==
        AuthSessionResponseClientInfoDeviceDevice.mobile;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        isMobile ? PhosphorIconsBold.deviceMobile : PhosphorIconsBold.monitor,
        size: 22,
        color: colors.textTertiary,
      ),
    );
  }

  Widget _info(BuildContext context, StarColorTheme colors) {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final clientOs = session.clientInfo?.os ?? l10n.linkedDevicesUnknownOs;
    final platformLabel =
        session.clientInfo?.platform ?? l10n.linkedDevicesUnknownPlatform;
    final location = authSessionLocationLabel(session.clientInfo?.location);
    final lastUsed = session.approxLastUsedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle(
          style: context.textStyles.categoryName.copyWith(
            color: colors.textPrimary,
          ),
          child: Text(
            session.clientInfo?.browser == null
                ? platformLabel
                : '$clientOs · $platformLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (!isCurrent && (location != null || lastUsed != null)) ...[
          SizedBox(height: layout.s1),
          DefaultTextStyle(
            style: context.textStyles.bodySmall.copyWith(fontSize: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (location != null)
                  Flexible(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (location != null && lastUsed != null) _dotSeparator(colors),
                if (lastUsed != null) Text(relativeTimeShort(lastUsed, l10n)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dotSeparator(StarColorTheme colors) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: colors.textTertiaryMuted,
        shape: BoxShape.circle,
      ),
    ),
  );

  Widget _trailing(
    BuildContext context,
    StarColorTheme colors,
    StarLocalizations l10n,
  ) {
    final layout = context.layout;
    if (selectionMode) {
      if (isCurrent) {
        return const SizedBox.shrink();
      }
      return _SelectionCheckbox(checked: isSelected, colors: colors);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: layout.s3,
      children: [
        if (onViewDetails != null)
          _DeviceActionButton(
            tooltip: l10n.linkedDevicesViewDetails,
            icon: PhosphorIconsBold.info,
            onTap: onViewDetails!,
          ),
        if (!isCurrent && isRevoking)
          const SizedBox(
            width: _kDeviceActionSize,
            height: _kDeviceActionSize,
            child: Center(child: StarLoadingSpinner()),
          )
        else if (!isCurrent && onRevoke != null)
          _DeviceActionButton(
            tooltip: l10n.linkedDevicesRevokeTooltip,
            icon: PhosphorIconsBold.x,
            onTap: onRevoke!,
            danger: true,
          ),
      ],
    );
  }
}

const double _kDeviceActionSize = 28;
const double _kDeviceActionIconSize = 14;

class _DeviceActionButton extends StatefulWidget {
  _DeviceActionButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.danger = false,
  }) : super(key: ValueKey(tooltip));

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  State<_DeviceActionButton> createState() => _DeviceActionButtonState();
}

class _DeviceActionButtonState extends State<_DeviceActionButton> {
  final ValueNotifier<({bool hovered, bool pressed})> _interaction =
      ValueNotifier((hovered: false, pressed: false));

  @override
  void dispose() {
    _interaction.dispose();
    super.dispose();
  }

  void _update({bool? hovered, bool? pressed}) {
    final current = _interaction.value;
    final next = (
      hovered: hovered ?? current.hovered,
      pressed: pressed ?? current.pressed,
    );
    if (next != current) {
      _interaction.value = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final BorderRadius radius = context.layout.radiusSm;

    return StarTooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        excludeSemantics: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _update(hovered: true),
          onExit: (_) => _update(hovered: false, pressed: false),
          child: Listener(
            onPointerDown: (_) => _update(pressed: true),
            onPointerUp: (_) => _update(pressed: false),
            onPointerCancel: (_) => _update(pressed: false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: ValueListenableBuilder<({bool hovered, bool pressed})>(
                valueListenable: _interaction,
                builder: (context, interaction, _) {
                  final hovered = interaction.hovered;
                  final pressed = interaction.pressed;
                  final Color background = pressed
                      ? colors.backgroundModifierSelected
                      : hovered
                      ? colors.backgroundModifierHover
                      : Colors.transparent;
                  final Color iconColor = pressed && widget.danger
                      ? colors.buttonDangerFill
                      : (hovered || pressed)
                      ? colors.textPrimary
                      : colors.textTertiary;
                  return Container(
                    width: _kDeviceActionSize,
                    height: _kDeviceActionSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: radius,
                      border: StarButtonVariant.secondary.border(
                        colors,
                        hovered: hovered,
                      ),
                    ),
                    child: PhosphorIcon(
                      widget.icon,
                      size: _kDeviceActionIconSize,
                      color: iconColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionCheckbox extends StatelessWidget {
  const _SelectionCheckbox({required this.checked, required this.colors});

  final bool checked;
  final StarColorTheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? colors.textPrimary : Colors.transparent,
        border: Border.all(
          color: checked ? colors.textPrimary : colors.textTertiaryMuted,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: checked
          ? PhosphorIcon(
              PhosphorIconsBold.check,
              size: 14,
              color: colors.backgroundPrimary,
            )
          : null,
    );
  }
}
