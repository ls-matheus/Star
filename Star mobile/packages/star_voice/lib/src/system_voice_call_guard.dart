import 'package:star_voice/src/messages.g.dart';

class StarSystemVoiceCallGuard {
  StarSystemVoiceCallGuard._();

  static final SystemVoiceCallGuardHostApi _api = SystemVoiceCallGuardHostApi();

  static Future<bool> isExternalCallActive({required bool starOwnsVoice}) {
    return _api.isExternalCallActive(starOwnsVoice: starOwnsVoice);
  }
}
