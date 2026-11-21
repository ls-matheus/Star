import 'package:star_app/features/guilds/presentation/widgets/guild_unavailable_screen.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class UnrecognizedChannelView extends StatelessWidget {
  const UnrecognizedChannelView({super.key});

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return GuildUnavailableScreen(
      title: l10n.channelUnsupportedTitle,
      description: l10n.channelUnsupportedBody,
      icon: PhosphorIconsFill.warningCircle,
    );
  }
}
