// ignore_for_file: document_ignores

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'star_voice',
    dartOut: 'lib/src/process_activity.g.dart',
    swiftOut: 'macos/star_voice/Sources/star_voice/ProcessActivity.g.swift',
    swiftOptions: SwiftOptions(
      errorClassName: 'StarVoiceProcessActivityError',
    ),
  ),
)
@HostApi()
abstract class VoiceProcessActivityHostApi {
  void begin();

  void end();
}
