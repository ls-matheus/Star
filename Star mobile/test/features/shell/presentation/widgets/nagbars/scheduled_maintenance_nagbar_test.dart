// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/shell/data/scheduled_maintenance_dismissal_storage.dart';
import 'package:star_app/features/shell/domain/service_status_maintenance.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/scheduled_maintenance_nagbar.dart';
import 'package:star_app/features/shell/providers/service_status/scheduled_maintenance_dismissal_provider.dart';
import 'package:star_app/features/shell/providers/service_status/service_status_maintenance_provider.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../../helpers/test_l10n.dart';
import '../../../../../helpers/wide_layout_test_sizes.dart';

void main() {
  group('ScheduledMaintenanceNagbar', () {
    final ServiceStatusMaintenance maintenance = ServiceStatusMaintenance(
      id: 'maint-1',
      status: ServiceStatusMaintenanceStatus.scheduled,
      start: DateTime.utc(2026, 7, 11, 18),
      durationMinutes: 60,
      url: 'https://status.example',
    );

    testWidgets('renders learn more action on desktop layout', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = kWideTestViewportSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _wrap(
          maintenance: maintenance,
          width: kWideTestViewportSize.width,
          child: const ScheduledMaintenanceNagbar(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StarNagbar), findsOneWidget);
      expect(find.text('Learn more'), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('uses column layout on mobile', (WidgetTester tester) async {
      final StarColorTheme colorTheme = buildDarkColorTheme();
      await tester.pumpWidget(
        MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          theme: buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
          home: Scaffold(
            body: StarNagbarContent(
              isMobile: true,
              message: 'Maintenance soon',
              onDismiss: () {},
              actions: const Text('Learn more'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });
  });
}

Widget _wrap({
  required ServiceStatusMaintenance maintenance,
  required Widget child,
  required double width,
}) {
  final StarColorTheme colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: <Override>[
      serviceStatusMaintenanceReadProvider.overrideWith(
        () => _FixedMaintenance(maintenance),
      ),
      scheduledMaintenanceDismissalStorageProvider.overrideWithValue(
        MapScheduledMaintenanceDismissalStorage(),
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
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

class _FixedMaintenance extends ServiceStatusMaintenanceRead {
  _FixedMaintenance(this._maintenance);

  final ServiceStatusMaintenance _maintenance;

  @override
  ServiceStatusMaintenance? build() => _maintenance;
}
