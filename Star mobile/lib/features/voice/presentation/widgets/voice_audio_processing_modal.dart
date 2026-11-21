import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/features/voice/presentation/widgets/voice_audio_processing_options.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showVoiceAudioProcessingModal(BuildContext context) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  return StarModal.show<void>(
    context,
    title: l10n.voiceAudioProcessing,
    builder: (BuildContext context, VoidCallback close) {
      return const VoiceAudioProcessingOptions();
    },
  );
}
