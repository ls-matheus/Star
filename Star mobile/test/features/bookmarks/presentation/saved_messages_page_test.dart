import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/bookmarks/data/saved_messages_repository.dart';
import 'package:star_app/features/bookmarks/domain/saved_messages.dart';
import 'package:star_app/features/bookmarks/presentation/saved_messages_page.dart';
import 'package:star_app/features/bookmarks/presentation/widgets/saved_messages_empty_state.dart';
import 'package:star_app/features/bookmarks/providers/saved_messages_provider.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../helpers/instance_runtime_config_override.dart';
import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_l10n.dart';

class _FetchedSavedMessages extends SavedMessagesNotifier {
  @override
  SavedMessagesState build() {
    return const SavedMessagesState(fetched: true, hasMore: false);
  }
}

class _EmptySavedMessagesRepository extends SavedMessagesRepository {
  _EmptySavedMessagesRepository(StarDatabase database)
    : super(
        database: database,
        client: StarClient(Dio()),
        currentUserId: 'viewer',
      );

  @override
  Future<SavedMessagesFetchPage> fetch({String? before}) async {
    return const SavedMessagesFetchPage(
      messages: <Message>[],
      missing: <SavedMessageMissingEntry>[],
      hasMore: false,
    );
  }
}

void main() {
  testWidgets('SavedMessagesPage renders bookmarks empty state', (
    WidgetTester tester,
  ) async {
    final StarDatabase db = openTestDatabase();
    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          starDatabaseProvider.overrideWithValue(db),
          savedMessagesProvider.overrideWith(_FetchedSavedMessages.new),
        ],
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          theme: buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
          home: const Scaffold(body: SavedMessagesPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Bookmarks'), findsOneWidget);
    expect(find.byType(SavedMessagesEmptyState), findsOneWidget);
    expect(find.text('No bookmarks'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('opening bookmarks fetches after the first frame', (
    WidgetTester tester,
  ) async {
    final StarDatabase db = openTestDatabase();
    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          instanceRuntimeConfigOverride(),
          starDatabaseProvider.overrideWithValue(db),
          savedMessagesRepositoryProvider.overrideWithValue(
            _EmptySavedMessagesRepository(db),
          ),
        ],
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          theme: buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
          home: const Scaffold(body: SavedMessagesPage()),
        ),
      ),
    );

    expect(find.byType(StarLoadingSpinner), findsOneWidget);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SavedMessagesEmptyState), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
