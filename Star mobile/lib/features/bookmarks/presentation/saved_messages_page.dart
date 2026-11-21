import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/bookmarks/presentation/widgets/message_list_page_shell.dart';
import 'package:star_app/features/bookmarks/presentation/widgets/saved_messages_body.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class SavedMessagesPage extends ConsumerWidget {
  const SavedMessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return MessageListPageShell(
      icon: PhosphorIcon(
        PhosphorIconsFill.bookmarkSimple,
        size: 24,
        color: context.colors.textPrimaryMuted,
      ),
      title: l10n.quickSwitcherBookmarksLabel,
      body: const SavedMessagesBody(),
    );
  }
}
