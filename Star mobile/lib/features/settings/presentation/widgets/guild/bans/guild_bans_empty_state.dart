import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class GuildBansEmptyState extends StatelessWidget {
  const GuildBansEmptyState({required this.l10n, super.key});

  final StarLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PhosphorIcon(
              PhosphorIconsFill.prohibit,
              size: 40,
              color: context.colors.textPrimaryMuted,
            ),
            SizedBox(height: context.layout.s3),
            Text(
              l10n.guildSettingsBansEmpty,
              style: context.textStyles.bodyMedium.copyWith(
                color: context.colors.textChat,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
