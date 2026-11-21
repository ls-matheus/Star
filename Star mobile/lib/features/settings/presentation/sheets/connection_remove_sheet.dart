import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/view_models/connections_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

class ConnectionRemoveSheet {
  const ConnectionRemoveSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required ConnectionResponse connection,
  }) {
    final l10n = StarLocalizations.of(context);
    return StarBottomSheet.show<void>(
      context,
      title: l10n.connectionRemoveTitle,
      useRootNavigator: true,
      builder: (sheetContext, close) =>
          _ConnectionRemoveBody(connection: connection, close: close),
    );
  }
}

class _ConnectionRemoveBody extends ConsumerWidget {
  const _ConnectionRemoveBody({required this.connection, required this.close});

  final ConnectionResponse connection;
  final VoidCallback close;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final colors = context.colors;

    return Padding(
      padding: settingsSheetScrollPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.connectionRemoveDescription,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: layout.s4),
          StarButton.dangerPrimary(
            label: l10n.connectionRemoveConfirm,
            onPressedAsync: () async {
              try {
                await ref
                    .read(
                      connectionsViewModelProvider(
                        readAccountUserId(ref),
                      ).notifier,
                    )
                    .deleteConnection(connection.type.toJson(), connection.id);
                if (context.mounted) {
                  close();
                }
              } on Object catch (_) {
                ref
                    .read(toastProvider.notifier)
                    .show(
                      StarToast(
                        message: l10n.connectionRemoveFailed,
                        variant: StarToastVariant.danger,
                      ),
                    );
              }
            },
          ),
        ],
      ),
    );
  }
}
