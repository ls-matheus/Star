import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class VoiceChannelJoinButton extends StatelessWidget {
  const VoiceChannelJoinButton({
    required this.onPressed,
    this.disabledTooltip,
    this.isLoading = false,
    this.label,
    super.key,
  });

  final VoidCallback? onPressed;
  final String? disabledTooltip;
  final bool isLoading;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final Widget button = StarButton.primary(
      onPressed: onPressed,
      isLoading: isLoading,
      label: label ?? l10n.voiceChannelJoin,
    );
    if (onPressed != null || disabledTooltip == null) {
      return button;
    }
    return Tooltip(message: disabledTooltip, child: button);
  }
}
