import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart' as db;
import 'package:star_app/features/chat/presentation/widgets/messages/message_item.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_list.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_list_skeleton.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_list_viewport.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../helpers/open_test_database.dart';
import '../../../../../helpers/pump_star_app.dart';
import 'message_list_test_harness.dart';

Set<int> _recordEpoch(WidgetTester tester, Set<int> epochs) {
  if (find.byType(MessageListViewport).evaluate().isNotEmpty) {
    epochs.add(messageListAnchorEpoch(tester));
  }
  return epochs;
}

Future<ValueNotifier<bool>> _pumpToggleableList(WidgetTester tester) async {
  configureMessageListViewport(tester);
  final db.StarDatabase database = openTestDatabase();
  addTearDown(database.close);
  final ValueNotifier<bool> shown = ValueNotifier<bool>(true);
  addTearDown(shown.dispose);
  final InstrumentedChatViewModel chatViewModel = InstrumentedChatViewModel(
    detachedState(seedMessages(40), hasMoreNewer: false),
  );
  await tester.pumpWidget(
    messageListApp(
      database: database,
      chatViewModel: chatViewModel,
      body: ValueListenableBuilder<bool>(
        valueListenable: shown,
        builder: (BuildContext context, bool visible, Widget? _) => visible
            ? const MessageList(expectedChannelId: messageListChannelId)
            : const SizedBox.shrink(),
      ),
    ),
  );
  return shown;
}

void main() {
  testWidgets('opening a channel with cached messages bumps anchorEpoch once', (
    WidgetTester tester,
  ) async {
    await _pumpToggleableList(tester);
    final Set<int> epochs = _recordEpoch(tester, <int>{});
    for (int i = 0; i < 8; i += 1) {
      await tester.pump();
      _recordEpoch(tester, epochs);
    }
    await pumpStarFrames(tester);
    _recordEpoch(tester, epochs);

    expect(find.byType(MessageItem), findsWidgets);
    expect(epochs, hasLength(1));
    await disposeMessageList(tester);
  });

  testWidgets('revisiting a channel anchors on the first frame', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<bool> shown = await _pumpToggleableList(tester);
    await pumpStarFrames(tester);
    expect(find.byType(MessageListViewport), findsOneWidget);

    shown.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    shown.value = true;
    await tester.pump();

    expect(find.byType(MessageListViewport), findsOneWidget);
    expect(find.byType(MessageListSkeleton), findsNothing);
    final Set<int> epochs = _recordEpoch(tester, <int>{});
    for (int i = 0; i < 8; i += 1) {
      await tester.pump();
      _recordEpoch(tester, epochs);
    }
    expect(epochs, hasLength(1));
    await disposeMessageList(tester);
  });

  testWidgets('read state is released after the retention window', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<bool> shown = await _pumpToggleableList(tester);
    await pumpStarFrames(tester);

    shown.value = false;
    await tester.pump();
    await tester.pump(
      kMessageListReadStateRetention + const Duration(seconds: 1),
    );
    shown.value = true;
    await tester.pump();

    expect(find.byType(MessageListViewport), findsNothing);
    expect(find.byType(MessageListSkeleton), findsOneWidget);
    await pumpStarFrames(tester);
    expect(find.byType(MessageListViewport), findsOneWidget);
    await disposeMessageList(tester);
  });
}
