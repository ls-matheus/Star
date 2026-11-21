import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/shell/domain/nagbar_state.dart';
import 'package:star_app/features/shell/domain/nagbar_type.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbar_container.dart';
import 'package:star_app/features/shell/providers/nagbar/nagbar_providers.dart';
import 'package:star_app/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../helpers/core_test_provider_overrides.dart';
import '../../../../helpers/test_l10n.dart';

void main() {
  testWidgets('NagbarContainer renders unclaimed account nagbar', (
    WidgetTester tester,
  ) async {
    final StarColorTheme colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      ProviderScope(
        overrides: coreTestProviderOverrides(
          extra: <Override>[
            visibleNagbarsProvider.overrideWith(
              (Ref ref) => <NagbarState>[
                const NagbarState(
                  type: NagbarType.unclaimedAccount,
                  priority: -4,
                  visible: true,
                  dismissible: false,
                ),
              ],
            ),
          ],
        ),
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          theme: buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
          home: const Scaffold(body: NagbarContainer()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('claim your account'), findsOneWidget);
  });
}
