import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class SlowmodeSendBlockedNotice extends StatelessWidget {
  const SlowmodeSendBlockedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        l10n.forwardSendSlowmodeBlocked,
        style: context.textStyles.bodySmall.copyWith(
          color: context.colors.textSecondary,
        ),
      ),
    );
  }
}
