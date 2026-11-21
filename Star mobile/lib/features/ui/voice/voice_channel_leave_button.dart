import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class VoiceChannelLeaveButton extends StatelessWidget {
  const VoiceChannelLeaveButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return StarButton.dangerSecondary(
      onPressed: onPressed,
      label: StarLocalizations.of(context).voiceChannelLeave,
    );
  }
}
