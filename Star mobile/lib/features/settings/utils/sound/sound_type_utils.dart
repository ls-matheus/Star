import 'package:star_app/core/audio/enums/star_sfx_clip.dart';
import 'package:star_app/features/settings/providers/preferences/sound_preferences_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

const String kSoundTypeDeaf = 'deaf';
const String kSoundTypeUndeaf = 'undeaf';
const String kSoundTypeMute = 'mute';
const String kSoundTypeUnmute = 'unmute';
const String kSoundTypeIncomingRing = 'incoming-ring';
const String kSoundTypeUserJoin = 'user-join';
const String kSoundTypeUserLeave = 'user-leave';
const String kSoundTypeUserMove = 'user-move';
const String kSoundTypeViewerJoin = 'viewer-join';
const String kSoundTypeViewerLeave = 'viewer-leave';
const String kSoundTypeVoiceDisconnect = 'voice-disconnect';
const String kSoundTypeCameraOn = 'camera-on';
const String kSoundTypeCameraOff = 'camera-off';
const String kSoundTypeScreenShareStart = 'screen-share-start';
const String kSoundTypeScreenShareStop = 'screen-share-stop';

const Set<String> kCommonNotificationSoundTypes = <String>{
  kSoundTypeMessage,
  kSoundTypeDirectMessage,
  kSoundTypeSameChannelMessage,
  kSoundTypeIncomingRing,
  kSoundTypeMute,
  kSoundTypeUnmute,
  kSoundTypeDeaf,
  kSoundTypeUndeaf,
};

const List<String> kAllNotificationSoundTypes = <String>[
  kSoundTypeMessage,
  kSoundTypeDirectMessage,
  kSoundTypeSameChannelMessage,
  kSoundTypeIncomingRing,
  kSoundTypeMute,
  kSoundTypeUnmute,
  kSoundTypeDeaf,
  kSoundTypeUndeaf,
  kSoundTypeUserJoin,
  kSoundTypeUserLeave,
  kSoundTypeUserMove,
  kSoundTypeViewerJoin,
  kSoundTypeViewerLeave,
  kSoundTypeVoiceDisconnect,
  kSoundTypeCameraOn,
  kSoundTypeCameraOff,
  kSoundTypeScreenShareStart,
  kSoundTypeScreenShareStop,
];

StarSfxClip? starSfxClipForSoundType(String soundType) {
  return switch (soundType) {
    kSoundTypeMessage => StarSfxClip.message,
    kSoundTypeDirectMessage => StarSfxClip.directMessage,
    kSoundTypeSameChannelMessage => StarSfxClip.sameChannelMessage,
    kSoundTypeDeaf => StarSfxClip.deaf,
    kSoundTypeUndeaf => StarSfxClip.undeaf,
    kSoundTypeMute => StarSfxClip.mute,
    kSoundTypeUnmute => StarSfxClip.unmute,
    kSoundTypeIncomingRing => StarSfxClip.incomingRing,
    kSoundTypeUserJoin => StarSfxClip.userJoin,
    kSoundTypeUserLeave => StarSfxClip.userLeave,
    kSoundTypeUserMove => StarSfxClip.userMove,
    kSoundTypeViewerJoin => StarSfxClip.viewerJoin,
    kSoundTypeViewerLeave => StarSfxClip.viewerLeave,
    kSoundTypeVoiceDisconnect => StarSfxClip.voiceDisconnect,
    kSoundTypeCameraOn => StarSfxClip.cameraOn,
    kSoundTypeCameraOff => StarSfxClip.cameraOff,
    kSoundTypeScreenShareStart => StarSfxClip.streamStart,
    kSoundTypeScreenShareStop => StarSfxClip.streamStop,
    _ => null,
  };
}

String? soundTypeForStarSfxClip(StarSfxClip clip) {
  return switch (clip) {
    StarSfxClip.message => kSoundTypeMessage,
    StarSfxClip.directMessage => kSoundTypeDirectMessage,
    StarSfxClip.sameChannelMessage => kSoundTypeSameChannelMessage,
    StarSfxClip.deaf => kSoundTypeDeaf,
    StarSfxClip.undeaf => kSoundTypeUndeaf,
    StarSfxClip.mute => kSoundTypeMute,
    StarSfxClip.unmute => kSoundTypeUnmute,
    StarSfxClip.incomingRing => kSoundTypeIncomingRing,
    StarSfxClip.userJoin => kSoundTypeUserJoin,
    StarSfxClip.userLeave => kSoundTypeUserLeave,
    StarSfxClip.userMove => kSoundTypeUserMove,
    StarSfxClip.viewerJoin => kSoundTypeViewerJoin,
    StarSfxClip.viewerLeave => kSoundTypeViewerLeave,
    StarSfxClip.voiceDisconnect => kSoundTypeVoiceDisconnect,
    StarSfxClip.cameraOn => kSoundTypeCameraOn,
    StarSfxClip.cameraOff => kSoundTypeCameraOff,
    StarSfxClip.streamStart => kSoundTypeScreenShareStart,
    StarSfxClip.streamStop => kSoundTypeScreenShareStop,
    StarSfxClip.pttActive || StarSfxClip.pttInactive => null,
  };
}

String notificationSoundTypeLabel(StarLocalizations l10n, String soundType) {
  return switch (soundType) {
    kSoundTypeMessage => l10n.notificationsSoundMessage,
    kSoundTypeDirectMessage => l10n.notificationsSoundDirectMessage,
    kSoundTypeSameChannelMessage => l10n.notificationsSoundSameChannelMessage,
    kSoundTypeMute => l10n.notificationsSoundMute,
    kSoundTypeUnmute => l10n.notificationsSoundUnmute,
    kSoundTypeDeaf => l10n.notificationsSoundDeaf,
    kSoundTypeUndeaf => l10n.notificationsSoundUndeaf,
    kSoundTypeUserJoin => l10n.notificationsSoundUserJoin,
    kSoundTypeUserLeave => l10n.notificationsSoundUserLeave,
    kSoundTypeUserMove => l10n.notificationsSoundUserMove,
    kSoundTypeViewerJoin => l10n.notificationsSoundViewerJoin,
    kSoundTypeViewerLeave => l10n.notificationsSoundViewerLeave,
    kSoundTypeVoiceDisconnect => l10n.notificationsSoundVoiceDisconnect,
    kSoundTypeIncomingRing => l10n.notificationsSoundIncomingRing,
    kSoundTypeCameraOn => l10n.notificationsSoundCameraOn,
    kSoundTypeCameraOff => l10n.notificationsSoundCameraOff,
    kSoundTypeScreenShareStart => l10n.notificationsSoundScreenShareStart,
    kSoundTypeScreenShareStop => l10n.notificationsSoundScreenShareStop,
    _ => soundType,
  };
}
