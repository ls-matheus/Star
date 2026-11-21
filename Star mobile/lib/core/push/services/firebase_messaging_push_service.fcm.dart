import 'package:star_app/core/push/android/pipeline.dart';
import 'package:star_app/core/push/fcm/fcm_tap_binding_host.dart';
import 'package:star_app/core/push/push_message.dart';
import 'package:star_app/core/push/push_service.dart';
import 'package:star_fcm/star_fcm_push_service.dart';

class FirebaseMessagingPushService implements PushService {
  const FirebaseMessagingPushService();

  static final StarFcmPushService _delegate = StarFcmPushService.instance;

  static FcmTapBindingHost get tapHost => _FcmTapBindingHostAdapter(_delegate);

  static StarFcmPushService get delegate => _delegate;

  static Stream<String> get tokenRefreshStream => _delegate.tokenRefreshStream;

  static Future<void> bootstrapAfterAuth() => _delegate.initialize();

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<String?> getToken() => _delegate.getToken();

  static final Stream<PushMessage> _messages = _delegate
      .watchCiphertext()
      .asyncExpand((String ciphertext) async* {
        final PushMessage? message = await AndroidPushPipeline.handleCiphertext(
          ciphertextBase64: ciphertext,
          backgroundMode: false,
        );
        if (message != null) {
          yield message;
        }
      });

  @override
  Stream<PushMessage> watchMessages() => _messages;
}

final class _FcmTapBindingHostAdapter implements FcmTapBindingHost {
  const _FcmTapBindingHostAdapter(this._delegate);

  final StarFcmPushService _delegate;

  @override
  void setNotificationTapCallback(FcmNotificationTapCallback? callback) {
    _delegate.setNotificationTapCallback(
      callback == null
          ? null
          : (Map<String, String> payload) => callback(payload),
    );
  }
}
