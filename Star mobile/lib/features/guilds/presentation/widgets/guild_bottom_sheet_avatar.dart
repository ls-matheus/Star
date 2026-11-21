import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/ui/avatar/star_guild_acronym.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/material_ui.dart';

class GuildBottomSheetAvatar extends StatelessWidget {
  final Guild guild;

  const GuildBottomSheetAvatar({required this.guild, super.key});

  @override
  Widget build(BuildContext context) {
    final iconUrl = guild.iconUrl;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: StarBottomSheet.cardColorOf(context),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: iconUrl != null
          ? CachedNetworkImage(
              imageUrl: iconUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => StarGuildAcronym(name: guild.name),
            )
          : StarGuildAcronym(name: guild.name),
    );
  }
}
