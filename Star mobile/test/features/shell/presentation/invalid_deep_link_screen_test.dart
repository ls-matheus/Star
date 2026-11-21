import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/router/route_names.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/shell/presentation/invalid_deep_link_screen.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('InvalidDeepLinkScreen', () {
    testWidgets('renders title, description, and go home button', (
      tester,
    ) async {
      await tester.pumpWidget(_buildRouterApp(initialLocation: '/missing'));
      await tester.pumpAndSettle();

      expect(find.text("Link couldn't be opened"), findsOneWidget);
      expect(
        find.text(
          'This link may be broken, only available on the web, or you might not have access. Check the link and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Go to home'), findsOneWidget);
    });

    testWidgets('go home button navigates to RoutePaths.me', (tester) async {
      final GoRouter router = _buildRouter(initialLocation: '/missing');
      addTearDown(router.dispose);

      await tester.pumpWidget(_buildRouterAppFromRouter(router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StarButton));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        RoutePaths.me,
      );
    });
  });
}

GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (BuildContext context, GoRouterState state) {
      return const InvalidDeepLinkScreen();
    },
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.me,
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(body: Text('home'));
        },
      ),
    ],
  );
}

Widget _buildRouterApp({required String initialLocation}) {
  final GoRouter router = _buildRouter(initialLocation: initialLocation);
  return _buildRouterAppFromRouter(router);
}

Widget _buildRouterAppFromRouter(GoRouter router) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp.router(
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    routerConfig: router,
  );
}
