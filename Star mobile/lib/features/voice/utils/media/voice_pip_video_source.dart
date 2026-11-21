import 'package:star_voice/star_voice.dart';
import 'package:livekit_client/livekit_client.dart';

VoicePipVideoSource? voicePipVideoSourceFor(VideoTrack track) {
  final String? trackId = track.mediaStreamTrack.id;
  if (trackId == null || trackId.isEmpty) {
    return null;
  }
  return VoicePipVideoSource.webRtcTrack(trackId);
}
