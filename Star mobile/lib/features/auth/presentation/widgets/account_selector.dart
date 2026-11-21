import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/domain/stored_account.dart';
import 'package:star_app/features/auth/presentation/widgets/account_row.dart';
import 'package:star_app/features/auth/providers/account_manager_provider.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class AccountSelector extends ConsumerWidget {
  const AccountSelector({
    required this.currentUserId,
    required this.onSelectAccount,
    required this.onAddAccount,
    super.key,
  });

  final String currentUserId;
  final void Function(StoredAccount account) onSelectAccount;
  final VoidCallback onAddAccount;

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    StoredAccount account, {
    required bool isCurrent,
  }) async {
    final l10n = StarLocalizations.of(context);
    final manager = ref.read(accountManagerProvider.notifier);

    await StarConfirmModal.show(
      context,
      title: l10n.signOut,
      description: l10n.accountRemoveDescription,
      confirmLabel: l10n.signOut,
      isDanger: true,
      onConfirm: () {
        if (isCurrent) {
          unawaited(manager.signOut(account.userId));
        } else {
          unawaited(manager.removeAccount(account.userId));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountManagerProvider);
    final accounts = state.accounts;

    if (accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);

    return AbsorbPointer(
      absorbing: state.isSwitchPending,
      child: AnimatedOpacity(
        opacity: state.isSwitchPending ? 0.5 : 1.0,
        duration: context.motion.fast,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.accountSelectorTitle,
              style: textStyles.heading.copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: layout.s2),
            Text(
              l10n.accountSelectorDescription,
              style: textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
            ),
            SizedBox(height: layout.s3),
            ...accounts.map(
              (account) => Padding(
                padding: EdgeInsets.only(bottom: layout.s2),
                child: AccountRow(
                  account: account,
                  isCurrent: account.userId == currentUserId,
                  onTap: () => onSelectAccount(account),
                  onSignOut: () => _confirmSignOut(
                    context,
                    ref,
                    account,
                    isCurrent: account.userId == currentUserId,
                  ),
                ),
              ),
            ),
            SizedBox(height: layout.s2),
            StarButton.secondary(
              onPressed: onAddAccount,
              label: l10n.accountAdd,
              icon: PhosphorIconsBold.plus,
              fitContent: true,
            ),
          ],
        ),
      ),
    );
  }
}
