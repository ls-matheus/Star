import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/connections_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/features/ui/toggle_switch/star_toggle_switch.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

class _VisibilityFlag {
  static const int everyone = 1;
  static const int friends = 2;
  static const int mutualGuilds = 4;
}

class ConnectionEditSheet {
  const ConnectionEditSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required ConnectionResponse connection,
  }) {
    final l10n = StarLocalizations.of(context);
    return StarBottomSheet.show<void>(
      context,
      title: l10n.connectionEditTitle,
      useRootNavigator: true,
      builder: (sheetContext, close) =>
          _ConnectionEditBody(connection: connection, close: close),
    );
  }
}

class _ConnectionEditBody extends ConsumerStatefulWidget {
  const _ConnectionEditBody({required this.connection, required this.close});

  final ConnectionResponse connection;
  final VoidCallback close;

  @override
  ConsumerState<_ConnectionEditBody> createState() =>
      _ConnectionEditBodyState();
}

class _ConnectionEditBodyState extends ConsumerState<_ConnectionEditBody> {
  late int _flags = widget.connection.visibilityFlags;

  bool _hasFlag(int flag) => (_flags & flag) == flag;

  void _toggle(int flag, bool value) {
    setState(() {
      _flags = value ? (_flags | flag) : (_flags & ~flag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final colors = context.colors;
    final everyoneEnabled = _hasFlag(_VisibilityFlag.everyone);

    return Padding(
      padding: settingsSheetScrollPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.connectionEditDescription,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: layout.s3),
          StarMenuGroup(
            children: [
              StarToggleSwitch(
                label: l10n.connectionVisibilityEveryone,
                description: l10n.connectionVisibilityEveryoneDesc,
                value: everyoneEnabled,
                onChanged: (v) => _toggle(_VisibilityFlag.everyone, v),
              ),
              StarToggleSwitch(
                label: l10n.connectionVisibilityFriends,
                description: l10n.connectionVisibilityFriendsDesc,
                value: everyoneEnabled || _hasFlag(_VisibilityFlag.friends),
                onChanged: (v) => _toggle(_VisibilityFlag.friends, v),
                enabled: !everyoneEnabled,
              ),
              StarToggleSwitch(
                label: l10n.connectionVisibilityCommunityMembers,
                description: l10n.connectionVisibilityCommunityMembersDesc,
                value:
                    everyoneEnabled || _hasFlag(_VisibilityFlag.mutualGuilds),
                onChanged: (v) => _toggle(_VisibilityFlag.mutualGuilds, v),
                enabled: !everyoneEnabled,
              ),
            ],
          ),
          SizedBox(height: layout.s4),
          StarButton.primary(label: l10n.save, onPressedAsync: _save),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final l10n = StarLocalizations.of(context);
    try {
      await ref
          .read(connectionsViewModelProvider(readAccountUserId(ref)).notifier)
          .updateVisibility(
            widget.connection.type.toJson(),
            widget.connection.id,
            _flags,
          );
      if (mounted) {
        widget.close();
      }
    } on Object catch (_) {
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.connectionUpdateFailed,
              variant: StarToastVariant.danger,
            ),
          );
    }
  }
}
