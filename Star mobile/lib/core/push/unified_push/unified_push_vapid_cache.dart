import 'package:star_app/core/database/star_database.dart';

bool hasUnifiedPushVapid(String? vapid) => vapid != null && vapid.isNotEmpty;

Future<String?> readCachedUnifiedPushVapidPublicKey(String instanceId) async {
  final StarDatabase database = StarDatabase();
  try {
    return await database.mobilePushRegistrationDao.getVapidForInstance(
      instanceId,
    );
  } finally {
    await database.close();
  }
}

Future<void> writeCachedUnifiedPushVapidPublicKey(
  String instanceId,
  String vapidPublicKey,
) async {
  if (instanceId.isEmpty || vapidPublicKey.isEmpty) {
    return;
  }
  final StarDatabase database = StarDatabase();
  try {
    await database.mobilePushRegistrationDao.saveVapidForInstance(
      instanceId: instanceId,
      vapidPublicKey: vapidPublicKey,
    );
  } finally {
    await database.close();
  }
}
