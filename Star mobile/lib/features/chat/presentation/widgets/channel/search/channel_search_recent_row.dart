import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/data/channel_search_history_repository.dart';
import 'package:star_app/features/chat/domain/channel_search_token.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/search/channel_search_suggestions.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/search/channel_search_token_chip.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class ChannelSearchRecentRow extends StatelessWidget {
  const ChannelSearchRecentRow({
    required this.entry,
    required this.guildId,
    required this.onTap,
    required this.onRemove,
    super.key,
  });

  final ChannelSearchHistoryEntry entry;
  final String? guildId;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final ({String text, List<ChannelSearchToken> tokens}) query = entry.query;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: kChannelSearchLeadingExtent,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: PhosphorIcon(
                    PhosphorIconsBold.clockCounterClockwise,
                    size: 18,
                    color: colors.textTertiary,
                  ),
                ),
              ),
              SizedBox(width: layout.s3),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: layout.s2),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      for (final ChannelSearchToken token in query.tokens)
                        ChannelSearchTokenChip(token: token, guildId: guildId),
                      if (query.text.isNotEmpty)
                        Text(
                          query.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodyMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              StarGestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: Semantics(
                  button: true,
                  label: l10n.channelSearchRemoveRecent,
                  child: SizedBox.square(
                    dimension: layout.s10,
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: PhosphorIcon(
                        PhosphorIconsBold.x,
                        size: 14,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
