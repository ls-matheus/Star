import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _androidAppRestartChannel = MethodChannel(
  'star_app/app_restart',
);

Future<void> restartAndroidApp() async {
  if (!Platform.isAndroid) {
    return;
  }
  await _androidAppRestartChannel.invokeMethod<void>('restart');
}
