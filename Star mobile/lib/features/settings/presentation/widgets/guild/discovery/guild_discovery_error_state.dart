import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class GuildDiscoveryErrorState extends StatelessWidget {
  const GuildDiscoveryErrorState({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.layout.s4),
        child: StarButton.secondary(
          label: l10n.retry,
          fitContent: true,
          onPressed: onRetry,
        ),
      ),
    );
  }
}
