import 'package:star_app/features/notifications/presentation/widgets/notifications_empty_state.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class MentionsEmptyState extends StatelessWidget {
  const MentionsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return NotificationsEmptyState(
      icon: PhosphorIconsBold.at,
      title: l10n.notificationsNoMentionsTitle,
      body: l10n.notificationsNoMentionsBody,
    );
  }
}
