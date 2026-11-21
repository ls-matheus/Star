import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/features/chat/presentation/widgets/messages/message_list.dart';

MessageListUnreadAckFields messageListUnreadAckFromReadState(
  db.ReadState? row,
) {
  return (
    manual: row?.manual ?? false,
    lastMessageId: row?.lastMessageId,
    mentionCount: row?.mentionCount ?? 0,
  );
}

Stream<MessageListUnreadAckFields> messageListUnreadAckStream([
  db.ReadState? row,
]) {
  return Stream<MessageListUnreadAckFields>.value(
    messageListUnreadAckFromReadState(row),
  );
}

Stream<MessageListUnreadAckFields> mapReadStateStreamToUnreadAck(
  Stream<db.ReadState?> source,
) {
  return source.map(messageListUnreadAckFromReadState);
}
