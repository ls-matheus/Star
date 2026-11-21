import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:star_app/core/audio/chat_attachment/chat_attachment_audio_session.dart';
import 'package:star_app/core/talker.dart';
import 'package:star_voice/star_voice.dart';

bool _loggedChannelFailure = false;

Future<bool> isExternalSystemVoiceCallActive({
  Future<bool> Function({required bool starOwnsVoice})? invokeNative,
}) async {
  final bool starOwnsVoice =
      ChatAttachmentAudioSession.instance.isVoiceCallActive ||
      StarVoiceAudioSession.instance.isActive;
  if (starOwnsVoice) {
    return false;
  }
  if (invokeNative != null) {
    return await invokeNative(starOwnsVoice: starOwnsVoice);
  }
  if (!(Platform.isIOS || Platform.isAndroid)) {
    return false;
  }
  try {
    return await StarSystemVoiceCallGuard.isExternalCallActive(
      starOwnsVoice: starOwnsVoice,
    );
  } on Object catch (error, stackTrace) {
    if (!_loggedChannelFailure) {
      _loggedChannelFailure = true;
      talker.warning(
        '[AudioSession] external call guard unavailable',
        error,
        stackTrace,
      );
    }
    return false;
  }
}

@visibleForTesting
void resetExternalSystemVoiceCallGuardForTest() {
  _loggedChannelFailure = false;
}
