import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/threads/presentation/thread_welcome_section.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class ChannelWelcomeSection extends StatelessWidget {
  const ChannelWelcomeSection({required this.channel, super.key});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    if (channel.isThread) {
      return ThreadWelcomeSection(thread: channel);
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String displayName = '#${channel.name}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRect(
            child: Text(
              displayName,
              style: context.textStyles.heading.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 4),
          ClipRect(
            child: Text(
              l10n.channelWelcomeDescription(displayName),
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textPrimaryMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
