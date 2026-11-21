import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:star_app/features/chat/providers/pickers/expression_picker_preferences_provider.dart';
import 'package:star_app/features/emoji/domain/emoji_attribution.dart';
import 'package:star_app/features/emoji/domain/emoji_info_data.dart';
import 'package:star_app/features/emoji/providers/emoji_info_provider.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/presentation/widgets/guild_bottom_sheet_avatar.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:star_app/shared/utils/emoji/emoji_image_cache.dart';
import 'package:star_app/shared/utils/emoji/emoji_registry.dart';
import 'package:star_app/shared/utils/emoji/emoji_utils.dart';
import 'package:star_app/shared/utils/star_haptics.dart';
import 'package:star_app/shared/widgets/unicode_emoji_widget.dart';
import 'package:star_markdown/star_markdown.dart';

const double _kEmojiPreviewSize = 36.7;

const Color kEmojiInfoScrimColor = Color(0xB0000000);

class EmojiInfoBottomSheet {
  EmojiInfoBottomSheet._();

  static Future<void> show(
    BuildContext context, {
    required EmojiInfoData emoji,
  }) {
    StarHaptics.medium();
    return StarBottomSheet.show<void>(
      context,
      barrierColor: usesDesktopPointerUi(context) ? null : kEmojiInfoScrimColor,
      desktop: const StarDesktopPresentation(
        surface: StarDesktopSurface.popout,
        width: 300,
        placement: StarDesktopPlacement.rightStart,
      ),
      builder: (sheetContext, close) {
        return _EmojiInfoBottomSheetContent(emoji: emoji);
      },
    );
  }
}

void openEmojiInfoBottomSheet(
  BuildContext context, {
  required EmojiInfoData emoji,
}) {
  unawaited(EmojiInfoBottomSheet.show(context, emoji: emoji));
}

void handleStarMarkdownEmojiLongPress(
  BuildContext context, {
  required String? emojiId,
  required String name,
  required bool animated,
  required bool isCustom,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  openEmojiInfoBottomSheet(
    context,
    emoji: EmojiInfoData.fromMarkdownLongPress(
      emojiId: emojiId,
      name: name,
      animated: animated,
    ),
  );
}

StarEmojiLongPressHandler get starMarkdownEmojiLongPressHandler =>
    handleStarMarkdownEmojiLongPress;

class _EmojiInfoBottomSheetContent extends ConsumerWidget {
  const _EmojiInfoBottomSheetContent({required this.emoji});

  final EmojiInfoData emoji;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);
    final resolvedAsync = ref.watch(emojiInfoResolvedProvider(emoji));
    final favoriteKeys =
        ref.watch(favoriteEmojiKeysProvider).value ?? const <String>[];

    final resolved =
        resolvedAsync.value ??
        const EmojiInfoResolved(
          attribution: EmojiAttribution(
            type: EmojiAttributionType.defaultEmoji,
          ),
        );
    final favoriteKey = resolved.favoriteKey;
    final isFavorite =
        favoriteKey != null && favoriteKeys.contains(favoriteKey);
    final showGuildSection = resolved.attribution.guild != null;

    final EmojiEntry? toneEntry = emoji.unicodeEntry;
    final bool showSkinTones = toneEntry != null && toneEntry.hasDiversity;

    return Padding(
      padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 2, top: 2),
                child: _EmojiPreview(emoji: emoji),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emoji.displayName,
                      style: context.textStyles.heading.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      emojiAttributionDescription(l10n, resolved.attribution),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall.copyWith(
                        fontSize: 16,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showGuildSection) ...[
            SizedBox(height: layout.s4),
            Divider(color: context.colors.borderColor, height: 1),
            SizedBox(height: layout.s4),
            Text(
              l10n.emojiInfoFromHeader,
              style: context.textStyles.label.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
            ),
            SizedBox(height: layout.s3),
            _GuildSourceRow(
              guild: resolved.attribution.guild!,
              l10n: l10n,
              isVerified: resolved.attribution.isVerified,
            ),
          ],
          if (showSkinTones) ...[
            SizedBox(height: layout.s4),
            _SkinToneRow(entry: toneEntry),
          ],
          if (favoriteKey != null) ...[
            SizedBox(height: layout.s4),
            Divider(color: context.colors.borderColor, height: 1),
            SizedBox(height: layout.s4),
            if (isFavorite)
              StarButton.secondary(
                label: l10n.emojiInfoRemoveFromFavorites,
                size: StarButtonSize.small,
                onPressed: () => _toggleFavorite(ref, favoriteKey),
              )
            else
              StarButton.primary(
                label: l10n.emojiInfoAddToFavorites,
                size: StarButtonSize.small,
                onPressed: () => _toggleFavorite(ref, favoriteKey),
              ),
          ],
        ],
      ),
    );
  }
}

void _toggleFavorite(WidgetRef ref, String favoriteKey) {
  StarHaptics.selection();
  unawaited(ref.read(favoriteEmojiKeysProvider.notifier).toggle(favoriteKey));
}

class _SkinToneRow extends ConsumerWidget {
  const _SkinToneRow({required this.entry});

  final EmojiEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String selected = ref.watch(emojiSkinToneProvider).value ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final String tone in <String>['', ...kSkinToneSurrogates])
          Semantics(
            button: true,
            selected: tone == selected,
            label: skinToneToName(tone) ?? entry.primaryName,
            child: StarGestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                StarHaptics.selection();
                unawaited(ref.read(emojiSkinToneProvider.notifier).set(tone));
              },
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone == selected
                      ? context.colors.backgroundModifierSelected
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: UnicodeEmojiWidget(
                  emoji: EmojiRegistry.resolveSkinToneSurrogates(entry, tone),
                  size: 32,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmojiPreview extends StatelessWidget {
  const _EmojiPreview({required this.emoji});

  final EmojiInfoData emoji;

  @override
  Widget build(BuildContext context) {
    if (emoji.isCustom) {
      return SizedBox(
        width: _kEmojiPreviewSize,
        height: _kEmojiPreviewSize,
        child: CachedEmojiImage(
          emojiId: emoji.id!,
          animated: emoji.animated,
          requestSize: kCustomEmojiFetchSize,
          size: _kEmojiPreviewSize,
        ),
      );
    }

    return SizedBox(
      width: _kEmojiPreviewSize,
      height: _kEmojiPreviewSize,
      child: UnicodeEmojiWidget(
        emoji: emoji.unicodeSurrogate,
        size: _kEmojiPreviewSize,
      ),
    );
  }
}

class _GuildSourceRow extends StatelessWidget {
  const _GuildSourceRow({
    required this.guild,
    required this.l10n,
    required this.isVerified,
  });

  final Guild guild;
  final StarLocalizations l10n;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final subtitle = guild.isDiscoverable
        ? l10n.emojiInfoDiscoverableCommunity
        : l10n.emojiInfoPrivateCommunity;

    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: GuildBottomSheetAvatar(guild: guild),
        ),
        SizedBox(width: layout.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      guild.name,
                      style: context.textStyles.label.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isVerified) ...[
                    SizedBox(width: layout.s1),
                    Tooltip(
                      message: l10n.emojiInfoVerifiedCommunity,
                      child: Icon(
                        PhosphorIconsFill.sealCheck,
                        size: 16,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: layout.s1_5),
              Text(
                subtitle,
                style: context.textStyles.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
