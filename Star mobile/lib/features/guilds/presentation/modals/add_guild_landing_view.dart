import 'package:star_app/features/guilds/presentation/modals/add_guild_action_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class AddGuildLandingView extends StatelessWidget {
  const AddGuildLandingView({
    required this.onCreateTap,
    required this.onJoinTap,
    this.onImportTap,
    super.key,
  });

  final VoidCallback onCreateTap;
  final VoidCallback onJoinTap;
  final VoidCallback? onImportTap;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: AddGuildActionButton(
                icon: PhosphorIconsFill.house,
                label: l10n.addGuildCreateCommunity,
                onTap: onCreateTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AddGuildActionButton(
                icon: PhosphorIconsBold.link,
                label: l10n.addGuildJoinCommunity,
                onTap: onJoinTap,
              ),
            ),
          ],
        ),
        if (onImportTap case final VoidCallback onImport) ...<Widget>[
          const SizedBox(height: 12),
          AddGuildActionButton(
            icon: PhosphorIconsBold.downloadSimple,
            label: l10n.addGuildImportDiscordTemplate,
            layout: AddGuildActionButtonLayout.row,
            onTap: onImport,
          ),
        ],
      ],
    );
  }
}
