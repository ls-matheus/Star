// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/features/bookmarks/data/saved_messages_repository.dart';
import 'package:star_app/features/bookmarks/domain/saved_messages.dart';
import 'package:star_app/features/bookmarks/providers/saved_messages_provider.dart';
import 'package:star_app/features/bookmarks/utils/saved_message_actions.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../helpers/open_test_database.dart';
import '../../../helpers/pump_star_app.dart';
import '../../../helpers/test_l10n.dart';

class _FakeSavedMessagesRepository extends SavedMessagesRepository {
  _FakeSavedMessagesRepository(this._db)
    : super(
        database: _db,
        client: StarClient(Dio()),
        currentUserId: 'user-1',
      );

  final StarDatabase _db;

  @override
  Future<void> saveMessage({
    required String channelId,
    required String messageId,
  }) async {
    await _db.savedMessageDao.addSavedMessage(messageId);
  }

  @override
  Future<void> unsaveMessage(String messageId) async {
    await _db.savedMessageDao.removeSavedMessage(messageId);
  }
}

class _SilentSavedMessages extends SavedMessagesNotifier {
  @override
  SavedMessagesState build() {
    return const SavedMessagesState(fetched: true, hasMore: false);
  }
}

void main() {
  const String channelId = 'channel-1';
  const String messageId = 'msg-1';

  Future<void> pumpHarness(
    WidgetTester tester, {
    required StarDatabase database,
    required Future<void> Function(WidgetRef ref) run,
  }) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      pumpStarApp(
        overrides: <Override>[
          starDatabaseProvider.overrideWithValue(database),
          savedMessagesRepositoryProvider.overrideWithValue(
            _FakeSavedMessagesRepository(database),
          ),
          savedMessagesProvider.overrideWith(_SilentSavedMessages.new),
        ],
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            capturedRef = ref;
            return const SizedBox();
          },
        ),
      ),
    );
    await run(capturedRef);
  }

  testWidgets('saving a message shows an added toast', (tester) async {
    final StarDatabase database = openTestDatabase();
    await pumpHarness(
      tester,
      database: database,
      run: (WidgetRef ref) async {
        await toggleSavedMessageBookmark(
          ref: ref,
          l10n: testL10n,
          channelId: channelId,
          messageId: messageId,
        );
        expect(await database.savedMessageDao.isSaved(messageId), isTrue);
        expect(
          ref.read(toastProvider).single.toast.message,
          testL10n.savedMessagesAddedToast,
        );
        expect(
          ref.read(toastProvider).single.toast.variant,
          StarToastVariant.success,
        );
      },
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('removing a bookmark shows a removed toast', (tester) async {
    final StarDatabase database = openTestDatabase();
    await database.savedMessageDao.addSavedMessage(messageId);
    await pumpHarness(
      tester,
      database: database,
      run: (WidgetRef ref) async {
        await toggleSavedMessageBookmark(
          ref: ref,
          l10n: testL10n,
          channelId: channelId,
          messageId: messageId,
        );
        expect(await database.savedMessageDao.isSaved(messageId), isFalse);
        expect(
          ref.read(toastProvider).single.toast.message,
          testL10n.savedMessagesRemovedToast,
        );
        expect(
          ref.read(toastProvider).single.toast.variant,
          StarToastVariant.success,
        );
      },
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
