import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/guilds/domain/guild.dart';
import 'package:star_app/features/guilds/providers/guild_providers.dart';
import 'package:star_app/features/guilds/utils/guild_outage_availability.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class StaffOnlyGuildNagbar extends ConsumerWidget {
  const StaffOnlyGuildNagbar({required this.guildId, super.key});

  final String guildId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Guild? guild = ref.watch(guildByIdProvider(guildId)).value;
    if (guild == null || !isGuildStaffOnlyAccessible(guild)) {
      return const SizedBox.shrink();
    }
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: context.colors.statusDanger,
      textColor: Colors.white,
      child: StarNagbarContent(
        isMobile: isMobile,
        message: l10n.guildStaffOnlyAccessibleNagbar(
          guild.name,
          ref.watch(
            instanceRuntimeConfigProvider.select(
              (config) => config.productName,
            ),
          ),
        ),
      ),
    );
  }
}
