import 'dart:async';

import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/bookmarks/presentation/widgets/message_list_page_shell.dart';
import 'package:star_app/features/notifications/presentation/widgets/mention_filters_sheet.dart';
import 'package:star_app/features/notifications/presentation/widgets/notifications_mentions_body.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class RecentMentionsPage extends StatelessWidget {
  const RecentMentionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return MessageListPageShell(
      icon: PhosphorIcon(
        PhosphorIconsFill.at,
        size: 24,
        color: context.colors.textPrimaryMuted,
      ),
      title: l10n.notificationsFilterMentions,
      trailing: Tooltip(
        message: l10n.notificationsMentionFilterTooltip,
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: () => unawaited(
            showMentionFiltersSheet(
              context,
              title: l10n.notificationsMentionFiltersTitle,
            ),
          ),
          icon: Icon(
            PhosphorIconsBold.funnel,
            color: context.colors.textSecondary,
            size: 22,
          ),
        ),
      ),
      body: const NotificationsMentionsBody(),
    );
  }
}
