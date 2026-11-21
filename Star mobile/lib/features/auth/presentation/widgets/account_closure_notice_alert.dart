import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/auth/providers/account_closure_notice_provider.dart';
import 'package:star_app/features/ui/warning_alert/star_warning_alert.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:intl/intl.dart';

class AccountClosureNoticeAlert extends ConsumerWidget {
  const AccountClosureNoticeAlert({required this.notice, super.key});

  final AccountClosureNotice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final DateTime? deletionAt = notice.deletionAt;
    final String message = switch (notice.kind) {
      AccountClosureKind.disabled => l10n.accountDisabledNotice,
      AccountClosureKind.immediateDeletion when notice.emailsEnabled =>
        l10n.accountDeletionImmediateNotice,
      AccountClosureKind.immediateDeletion =>
        l10n.accountDeletionImmediateNoticeNoEmail,
      AccountClosureKind.scheduledDeletion when deletionAt != null =>
        l10n.accountDeletionScheduledNotice(
          DateFormat.yMMMMd(l10n.localeName).format(deletionAt),
        ),
      AccountClosureKind.scheduledDeletion =>
        l10n.accountDeletionScheduledNoticeNoDate,
    };
    return StarWarningAlert(
      variant: StarAlertVariant.info,
      message: message,
      dismissLabel: l10n.uiClose,
      onDismiss: ref.read(pendingAccountClosureNoticeProvider.notifier).clear,
    );
  }
}
