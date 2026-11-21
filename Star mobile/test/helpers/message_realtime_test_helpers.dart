import 'package:star_app/features/chat/providers/messages/message_realtime_events.dart';
import 'package:star_dart/gateway.dart';

MessageCreated testMessageCreated(
  MessageCreateEvent event, {
  MessagePersistSnapshot? snapshot,
}) {
  return MessageCreated(
    event: event,
    snapshot:
        snapshot ??
        const MessagePersistSnapshot(
          mentionsCurrentUser: false,
          isDm: false,
          acknowledgedByGateway: false,
        ),
  );
}
