import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/expression_picker.dart';
import 'package:star_app/features/chat/utils/messages/double_tap_reaction.dart';
import 'package:star_app/features/ui/emoji_picker/star_emoji_picker_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showDoubleTapReactionPicker(
  BuildContext context,
  WidgetRef ref, {
  String? channelId,
}) {
  final l10n = StarLocalizations.of(context);
  return StarEmojiPickerSheet.show(
    context,
    title: l10n.doubleTapReactionEditTitle,
    subtitle: Text(
      l10n.doubleTapReactionEditSubtitle,
      style: context.textStyles.bodySmall.copyWith(
        color: context.colors.textSecondary,
      ),
    ),
    channelId: channelId,
    visibleTabs: const [ExpressionPickerTab.emojis],
    onEmojiSelected: (emoji) {
      unawaited(saveSelectedDoubleTapReaction(ref, emoji));
    },
  );
}
