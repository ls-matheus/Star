import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/checkbox/star_checkbox.dart';
import 'package:star_app/features/ui/focus_ring/star_focus_ring.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/keybind_hint/star_keybind_hint.dart';
import 'package:star_app/features/ui/radio_group/star_radio_group.dart';
import 'package:star_app/features/ui/select/star_select.dart';
import 'package:star_app/features/ui/slider/star_slider.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/features/ui/tabs/star_segmented_tabs.dart';
import 'package:star_app/features/ui/tabs/star_tabs.dart';
import 'package:star_app/features/ui/toggle_switch/star_toggle_switch.dart';
import 'package:star_app/features/ui/warning_alert/star_warning_alert.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

import '../../helpers/input_modality_override.dart';
import '../../helpers/wide_layout_test_sizes.dart';

Widget _app({required bool touch, required Widget child}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [inputModalityOverride(touch: touch)],
    child: MaterialApp(
      localizationsDelegates: StarLocalizations.localizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

Widget _gallery() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: [
      StarButton.primary(onPressed: () {}, label: 'Save'),
      StarButton.secondary(
        onPressed: () {},
        label: 'Cancel',
        size: StarButtonSize.small,
      ),
      StarButton.dangerPrimary(
        onPressed: () {},
        label: 'Delete',
        size: StarButtonSize.compact,
      ),
      StarButton.ghost(
        onPressed: () {},
        label: 'More',
        size: StarButtonSize.superCompact,
      ),
      StarButton.primary(onPressed: () {}, label: 'Busy', isLoading: true),
      const StarInput(label: 'Name', hint: 'Type here'),
      StarSelect<String>(
        label: 'Pick',
        hint: 'Choose',
        enableSearch: false,
        items: const [StarSelectItem(value: 'a', label: 'A')],
        value: 'a',
        onChanged: (_) {},
      ),
      StarCheckbox(value: true, onChanged: (_) {}, label: 'Check'),
      StarRadioGroup<String>(
        value: 'a',
        items: const [
          StarRadioItem(value: 'a', label: 'A', description: 'First'),
          StarRadioItem(value: 'b', label: 'B'),
        ],
        onChanged: (_) {},
      ),
      StarToggleSwitch(value: true, onChanged: (_) {}, label: 'Toggle'),
      StarTabs(
        tabs: const [
          StarTab(label: 'One'),
          StarTab(label: 'Two'),
        ],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
      StarSegmentedTabs(
        tabs: const [
          StarTab(label: 'Day'),
          StarTab(label: 'Week'),
        ],
        selectedIndex: 1,
        onChanged: (_) {},
      ),
      const StarWarningAlert(title: 'Heads up', message: 'Careful'),
      const StarKeybindHint(keys: ['⌘', 'K']),
      const StarFocusRing(focused: true, child: Text('Focus')),
      const SizedBox(width: 280, child: StarSlider(defaultValue: 40)),
    ],
  );
}

void main() {
  testWidgets('desktop primitives use web metrics', (tester) async {
    tester.view.physicalSize = kWideTestViewportSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(touch: false, child: _gallery()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(StarButton).first).height, 36);
    expect(tester.getSize(find.byType(StarButton).at(1)).height, 34);
    expect(tester.getSize(find.byType(StarButton).at(3)).height, 26);
    expect(find.byType(StarPulsingEllipsis), findsOneWidget);
    expect(tester.getSize(find.byType(TextField)).height, 44);
  });

  testWidgets('touch primitives keep mobile metrics', (tester) async {
    tester.view.physicalSize = kWideTestViewportSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(touch: true, child: _gallery()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(StarButton).first).height, 44);
    expect(find.byType(StarPulsingEllipsis), findsNothing);
  });
}
