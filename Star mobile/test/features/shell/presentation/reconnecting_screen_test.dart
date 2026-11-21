import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/database/star_database.dart'
    show StarDatabase;
import 'package:star_app/core/providers/app/app_ui_lifecycle_provider.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/providers/gateway/gateway_connection_provider.dart';
import 'package:star_app/core/router/star_router.dart';
import 'package:star_app/features/auth/domain/stored_account.dart';
import 'package:star_app/features/auth/providers/account_manager_provider.dart';
import 'package:star_app/features/shell/domain/service_status_incident.dart';
import 'package:star_app/features/shell/presentation/reconnecting_screen.dart';
import 'package:star_app/features/shell/providers/service_status/service_status_incident_provider.dart';
import 'package:star_app/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../helpers/open_test_database.dart';
import '../../../helpers/pump_star_app.dart';
import '../../../helpers/test_l10n.dart';

class _SignedIn extends AuthState {
  @override
  bool build() => true;
}

class _NoopIncidentRead extends ServiceStatusIncidentRead {
  @override
  ServiceStatusIncident? build() => null;

  @override
  Future<void> refresh() async {}
}

class _NoAccounts extends AccountManager {
  @override
  AccountManagerState build() => const AccountManagerState(
    accounts: <StoredAccount>[],
    isSwitching: false,
  );

  @override
  Future<void> loadAccounts() async {}
}

late StarDatabase _database;

void main() {
  setUp(() {
    _database = openTestDatabase();
  });

  testWidgets('signed in without a token never builds the gateway', (
    tester,
  ) async {
    await tester.pumpWidget(
      pumpStarApp(
        overrides: <Override>[
          starDatabaseProvider.overrideWithValue(_database),
          authStateProvider.overrideWith(_SignedIn.new),
          serviceStatusIncidentReadProvider.overrideWith(_NoopIncidentRead.new),
          accountManagerProvider.overrideWith(_NoAccounts.new),
        ],
        child: const ReconnectingScreen(),
      ),
    );
    await tester.pump();
    await tester.pump();

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(ReconnectingScreen)),
    );
    expect(container.read(starAuthTokenProvider), isNull);
    expect(container.read(gatewayConnectionProvider.exists), isFalse);
    expect(find.text(testL10n.reconnectingTitle), findsOneWidget);

    container.read(appUiForegroundProvider.notifier).setResumed(false);
    await tester.pump();
    container.read(appUiForegroundProvider.notifier).setResumed(true);
    await tester.pump();
    await tester.pump(kReconnectingScreenRetryInterval);

    expect(container.read(gatewayConnectionProvider.exists), isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
