import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/presentation/widgets/guild_folder_menu_data.dart';
import 'package:star_app/features/guilds/providers/organized_guild_list_provider.dart';
import 'package:star_app/features/guilds/utils/guild_folder_icon.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/color_picker/star_color_picker_field.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/features/ui/select/star_select.dart';
import 'package:star_app/features/ui/toggle_switch/star_toggle_switch.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class GuildFolderSettingsModal extends ConsumerStatefulWidget {
  const GuildFolderSettingsModal({required this.folderId, super.key});

  final int folderId;

  static Future<void> show(BuildContext context, {required int folderId}) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    if (isMobileLayout(context)) {
      final layout = context.layout;
      return StarBottomSheet.show<void>(
        context,
        title: l10n.guildFolderSettingsTitle,
        useRootNavigator: true,
        builder: (BuildContext sheetContext, VoidCallback close) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, 0),
            child: GuildFolderSettingsModal(folderId: folderId),
          );
        },
      );
    }
    return StarModal.show<void>(
      context,
      title: l10n.guildFolderSettingsTitle,
      centered: true,
      builder: (BuildContext dialogContext, VoidCallback close) {
        return GuildFolderSettingsModal(folderId: folderId);
      },
      actionsBuilder: (void Function([void]) pop) => const <Widget>[],
    );
  }

  @override
  ConsumerState<GuildFolderSettingsModal> createState() =>
      _GuildFolderSettingsModalState();
}

class _GuildFolderSettingsModalState
    extends ConsumerState<GuildFolderSettingsModal> {
  final TextEditingController _nameController = TextEditingController();
  var _color = 0;
  var _flags = 0;
  var _icon = 'folder';
  var _isSaving = false;
  var _isDeleting = false;
  var _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  GuildNavbarFolder? _watchFolder() {
    for (final GuildNavbarItem item in ref.watch(organizedGuildListProvider)) {
      if (item is GuildNavbarFolder && item.id == widget.folderId) {
        return item;
      }
    }
    return null;
  }

  String _derivedFolderName(GuildNavbarFolder folder) {
    return folder.guilds.take(3).map((guild) => guild.name).join(', ');
  }

  void _initFromFolder(GuildNavbarFolder folder) {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _nameController.text = folder.name ?? '';
    _color = folder.color ?? 0;
    _flags = folder.flags;
    _icon = folder.icon ?? 'folder';
  }

  Future<void> _handleSave(GuildNavbarFolder folder) async {
    setState(() => _isSaving = true);
    final String trimmed = _nameController.text.trim();
    ref
        .read(organizedGuildListProvider.notifier)
        .updateFolder(
          widget.folderId,
          name: trimmed.isEmpty ? null : trimmed,
          color: _color == 0 ? null : _color,
          flags: _flags,
          icon: _icon,
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    try {
      ref
          .read(organizedGuildListProvider.notifier)
          .dissolveFolder(widget.folderId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final folder = _watchFolder();
    if (folder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }
    _initFromFolder(folder);

    final String placeholder = _derivedFolderName(folder);
    final bool showCollapsedIcon = (_flags & 1) != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StarInput(
          controller: _nameController,
          label: l10n.guildFolderNameLabel,
          hint: placeholder,
          maxLength: 100,
          autofocus: true,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
        SizedBox(height: layout.s3),
        StarColorPickerField(
          label: l10n.guildFolderColorLabel,
          value: _color,
          onChanged: (int value) => setState(() => _color = value),
        ),
        SizedBox(height: layout.s3),
        StarToggleSwitch(
          label: l10n.guildFolderShowIconWhenCollapsed,
          value: showCollapsedIcon,
          onChanged: (bool value) {
            setState(() {
              if (value) {
                _flags |= 1;
              } else {
                _flags &= ~1;
              }
            });
          },
        ),
        SizedBox(height: layout.s3),
        StarSelect<String>(
          label: l10n.guildFolderIconLabel,
          value: _icon,
          enableSearch: false,
          items: [
            for (final String iconId in kGuildFolderIconIds)
              StarSelectItem<String>(
                value: iconId,
                label: guildFolderIconLabel(l10n, iconId),
                leading: PhosphorIcon(guildFolderIconForName(iconId), size: 18),
              ),
          ],
          onChanged: (String value) => setState(() => _icon = value),
        ),
        SizedBox(height: layout.s4),
        SizedBox(
          width: double.infinity,
          child: StarButton.dangerPrimary(
            onPressed: _isDeleting || _isSaving ? null : _handleDelete,
            label: l10n.guildFolderDelete,
            isLoading: _isDeleting,
          ),
        ),
        SizedBox(height: layout.s2),
        Row(
          children: [
            Expanded(
              child: StarButton.secondary(
                onPressed: _isSaving || _isDeleting
                    ? null
                    : () => Navigator.of(context).pop(),
                label: l10n.cancel,
              ),
            ),
            SizedBox(width: layout.s2),
            Expanded(
              child: StarButton.primary(
                onPressed: _isSaving || _isDeleting
                    ? null
                    : () => unawaited(_handleSave(folder)),
                label: l10n.save,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
