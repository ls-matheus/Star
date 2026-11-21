import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/header/channel_header_icon_button.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

import '../../../../../../helpers/test_l10n.dart';

class _TouchPrimaryModality extends InputModalityNotifier {
  @override
  bool build() => true;
}

void main() {
  testWidgets('uses touch target min size when touch-primary', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inputModalityProvider.overrideWith(_TouchPrimaryModality.new),
        ],
        child: _buildApp(
          const ChannelHeaderIconButton(
            icon: Icons.star,
            label: 'Favorite',
            onPressed: _noop,
          ),
        ),
      ),
    );
    await tester.pump();

    final SizedBox box = tester.widget<SizedBox>(
      find
          .descendant(
            of: find.byType(ChannelHeaderIconButton),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(box.width, 44);
    expect(box.height, 44);
  });
}

void _noop() {}

Widget _buildApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    locale: kTestLocale,
    localizationsDelegates: starLocalizationsDelegates,
    supportedLocales: StarLocalizations.supportedLocales,
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}
