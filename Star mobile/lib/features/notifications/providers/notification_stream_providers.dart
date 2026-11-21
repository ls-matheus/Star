import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/database/star_database.dart' hide Message;
import 'package:star_app/core/providers/database_provider.dart';

final StreamProvider<List<NotificationMentionFeedData>>
notificationMentionFeedStreamProvider =
    StreamProvider<List<NotificationMentionFeedData>>((Ref ref) {
      final StarDatabase db = ref.watch(starDatabaseProvider);
      return db.notificationDao.watchMentionFeedOrdered();
    });
