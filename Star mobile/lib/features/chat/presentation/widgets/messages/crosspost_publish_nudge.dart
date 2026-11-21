import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/sheets/publish_message_sheets.dart';
import 'package:star_app/features/chat/providers/publish_nudge_provider.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class CrosspostPublishNudge extends ConsumerWidget {
  const CrosspostPublishNudge({required this.message, super.key});

  final Message message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? nudgeId = ref.watch(publishNudgeMessageIdProvider);
    if (nudgeId != message.id) {
      return const SizedBox.shrink();
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          PhosphorIcon(
            PhosphorIconsBold.megaphone,
            size: 16,
            color: context.colors.textTertiary,
          ),
          Text(
            l10n.publishNudgeNotSent,
            style: context.textStyles.smallText.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          StarButton.primary(
            onPressed: () => unawaited(
              publishMessage(ref: ref, context: context, message: message),
            ),
            label: l10n.chatMessagePublish,
            size: StarButtonSize.small,
            fitContent: true,
          ),
          StarButton.secondary(
            onPressed: () => ref
                .read(publishNudgeControllerProvider.notifier)
                .dismiss(message.id),
            label: l10n.publishNudgeDismiss,
            size: StarButtonSize.small,
            fitContent: true,
          ),
          StarButton.ghost(
            onPressed: () => unawaited(
              ref.read(publishNudgeControllerProvider.notifier).hideForever(),
            ),
            label: l10n.publishNudgeHideForever,
            size: StarButtonSize.small,
            fitContent: true,
          ),
        ],
      ),
    );
  }
}
