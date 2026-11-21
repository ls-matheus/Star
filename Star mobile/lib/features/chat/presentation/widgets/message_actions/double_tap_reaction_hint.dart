import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/sheets/double_tap_reaction_picker_sheet.dart';
import 'package:star_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:star_app/features/chat/utils/messages/double_tap_reaction.dart';
import 'package:star_app/features/settings/providers/preferences/appearance_preferences_provider.dart';
import 'package:star_app/features/settings/providers/preferences/message_ui_preferences_providers.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/features/ui/text_link/star_text_link.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_app/shared/utils/emoji/emoji_image_cache.dart';
import 'package:star_app/shared/utils/emoji/emoji_utils.dart';
import 'package:star_app/shared/widgets/unicode_emoji_widget.dart';

const double kDoubleTapReactionPreviewSize = 16;

class DoubleTapReactionGlyph extends ConsumerWidget {
  const DoubleTapReactionGlyph({
    this.size = kDoubleTapReactionPreviewSize,
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(doubleTapReactionPreferencesProvider);
    final emojiId = pref.id;
    if (emojiId == null || emojiId.isEmpty) {
      return UnicodeEmojiWidget(emoji: pref.name, size: size);
    }
    final emojis =
        ref.watch(allGuildEmojisForPickerProvider).value ??
        const <GuildEmojiEntry>[];
    return CachedEmojiImage(
      emojiId: emojiId,
      animated: customEmojiAnimated(emojis, emojiId),
      requestSize: kCustomEmojiFetchSize,
      size: size,
    );
  }
}

class DoubleTapReactionHint extends ConsumerWidget {
  const DoubleTapReactionHint({this.channelId, super.key});

  final String? channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(inputModalityProvider)) {
      return const SizedBox.shrink();
    }
    final l10n = StarLocalizations.of(context);
    final DoubleTapActionPreference action = ref.watch(
      doubleTapActionPreferencesProvider.select((s) => s.effectiveAction),
    );
    final muted = context.textStyles.bodySmall.copyWith(
      color: context.colors.textTertiaryMuted,
    );
    final padding = EdgeInsets.only(bottom: context.layout.s1_5);
    switch (action) {
      case DoubleTapActionPreference.none:
      case DoubleTapActionPreference.unspecified:
        return const SizedBox.shrink();
      case DoubleTapActionPreference.edit:
        return Padding(
          padding: padding,
          child: Text(
            l10n.doubleTapEditHint,
            style: muted,
            textAlign: TextAlign.center,
          ),
        );
      case DoubleTapActionPreference.react:
        break;
    }
    void changeEmoji() => unawaited(
      showDoubleTapReactionPicker(context, ref, channelId: channelId),
    );
    return Padding(
      padding: padding,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(l10n.doubleTapReactionHint, style: muted),
          StarGestureDetector(
            onTap: changeEmoji,
            excludeFromSemantics: true,
            child: const DoubleTapReactionGlyph(),
          ),
          StarTextLink(
            text: l10n.doubleTapReactionEdit,
            onTap: changeEmoji,
            style: context.textStyles.bodySmall,
            underline: ref.watch(
              appearancePreferencesProvider.select(
                (s) => s.alwaysUnderlineLinks,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
