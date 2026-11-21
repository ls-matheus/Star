import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class StarFcmBootstrap {
  StarFcmBootstrap._();

  static Future<void> bootstrapIfNeeded({
    required Future<void> Function(RemoteMessage message) onBackgroundMessage,
  }) async {
    try {
      FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[StarFcmBootstrap] background handler registration failed: '
          '$error\n$stackTrace',
        );
      }
      rethrow;
    }
  }
}
