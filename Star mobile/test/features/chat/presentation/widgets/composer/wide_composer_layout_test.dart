import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/voice_message_recording_bar.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/wide_composer_layout.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/l10n/generated/star_localizations_en.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../../helpers/composer_channel_textarea_harness.dart';
import '../../../../../helpers/open_test_database.dart';

class _MousePrimaryModality extends InputModalityNotifier {
  @override
  bool build() => false;
}

class _TouchPrimaryModality extends InputModalityNotifier {
  @override
  bool build() => true;
}

Future<void> _pumpWideComposer(
  WidgetTester tester, {
  List<Override> extraOverrides = const <Override>[],
}) async {
  await pumpComposerChannelTextareaHarness(
    tester,
    extraOverrides: extraOverrides,
  );
  tester.view.physicalSize = const Size(1400, 900);
  await tester.pumpAndSettle();
}

Finder _wideComposerRowSlot({required double rowMinHeight}) {
  return find.byWidgetPredicate((Widget widget) {
    if (widget is! ConstrainedBox) {
      return false;
    }
    final BoxConstraints constraints = widget.constraints;
    return constraints.minHeight == rowMinHeight && constraints.minWidth == 0;
  });
}

void _expectFieldAlignedWithAttach(
  WidgetTester tester, {
  required double rowMinHeight,
}) {
  final Finder field = channelComposerField();
  final Finder rowSlot = find.ancestor(
    of: field,
    matching: _wideComposerRowSlot(rowMinHeight: rowMinHeight),
  );
  expect(rowSlot, findsOneWidget);
  final Finder attachButton = find.descendant(
    of: rowSlot,
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is WideComposerMouseButton &&
          widget.tooltip == StarLocalizationsEn().chatAttachmentSourceBrowse,
    ),
  );
  expect(attachButton, findsOneWidget);

  final double fieldCenterY = tester.getRect(field).center.dy;
  final double attachCenterY = tester.getRect(attachButton).center.dy;
  expect(fieldCenterY - attachCenterY, closeTo(0, 2));
}

void _expectIdleRowUsesActionHeightMin(
  WidgetTester tester, {
  required StarButtonSize actionSize,
}) {
  final Finder rowSlot = _wideComposerRowSlot(rowMinHeight: actionSize.height);
  expect(rowSlot, findsOneWidget);
  final ConstrainedBox constrained = tester.widget<ConstrainedBox>(rowSlot);
  expect(constrained.constraints.minHeight, actionSize.height);
}

void _expectWideRowHorizontalInset(
  WidgetTester tester, {
  required double inset,
  required StarButtonSize actionSize,
}) {
  final Finder rowSlot = _wideComposerRowSlot(rowMinHeight: actionSize.height);
  expect(rowSlot, findsOneWidget);
  final Padding padding = tester
      .element(rowSlot)
      .findAncestorWidgetOfExactType<Padding>()!;
  final EdgeInsets resolved = padding.padding.resolve(TextDirection.ltr);
  expect(resolved.left, inset);
  expect(resolved.right, inset);
}

Future<void> _clearComposerDraft(WidgetTester tester) async {
  await tester.enterText(channelComposerField(), '');
  await tester.pumpAndSettle();
}

void main() {
  group('wide composer widget layout', () {
    testWidgets('centers the text field in the padded slot (mouse)', (
      WidgetTester tester,
    ) async {
      await _pumpWideComposer(
        tester,
        extraOverrides: <Override>[
          inputModalityProvider.overrideWith(_MousePrimaryModality.new),
        ],
      );
      await _clearComposerDraft(tester);
      _expectFieldAlignedWithAttach(
        tester,
        rowMinHeight: StarButtonSize.compact.height,
      );
      _expectIdleRowUsesActionHeightMin(
        tester,
        actionSize: StarButtonSize.compact,
      );
      _expectWideRowHorizontalInset(
        tester,
        inset: WideComposerLayout.densePaddingXMouse,
        actionSize: StarButtonSize.compact,
      );
      await releaseTestWidgetTree(tester);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('keeps mouse buttons on the first line when multi-line', (
      WidgetTester tester,
    ) async {
      await _pumpWideComposer(
        tester,
        extraOverrides: <Override>[
          inputModalityProvider.overrideWith(_MousePrimaryModality.new),
        ],
      );
      await _clearComposerDraft(tester);
      final Finder rowSlot = _wideComposerRowSlot(
        rowMinHeight: StarButtonSize.compact.height,
      );
      final Finder attachButton = find.descendant(
        of: rowSlot,
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is WideComposerMouseButton &&
              widget.tooltip ==
                  StarLocalizationsEn().chatAttachmentSourceBrowse,
        ),
      );
      final double singleLineTop = tester.getRect(attachButton).top;
      final double singleLineRowTop = tester.getRect(rowSlot).top;

      await tester.enterText(channelComposerField(), 'one\ntwo\nthree');
      await tester.pumpAndSettle();

      expect(
        tester.getRect(rowSlot).height,
        greaterThan(StarButtonSize.compact.height),
      );
      expect(
        tester.getRect(attachButton).top - tester.getRect(rowSlot).top,
        closeTo(singleLineTop - singleLineRowTop, 0.5),
      );
      await releaseTestWidgetTree(tester);
    });

    testWidgets('aligns touch wide row controls on one baseline', (
      WidgetTester tester,
    ) async {
      await _pumpWideComposer(
        tester,
        extraOverrides: <Override>[
          inputModalityProvider.overrideWith(_TouchPrimaryModality.new),
        ],
      );
      await _clearComposerDraft(tester);
      _expectIdleRowUsesActionHeightMin(
        tester,
        actionSize: StarButtonSize.small,
      );
      _expectWideRowHorizontalInset(
        tester,
        inset: WideComposerLayout.densePaddingXTouch,
        actionSize: StarButtonSize.small,
      );
      await releaseTestWidgetTree(tester);
    });

    testWidgets('voice recording bar uses the wide slot height contract', (
      WidgetTester tester,
    ) async {
      await _pumpWideComposer(
        tester,
        extraOverrides: <Override>[
          inputModalityProvider.overrideWith(_MousePrimaryModality.new),
        ],
      );
      await _clearComposerDraft(tester);

      final Finder voice = find.byKey(const ValueKey<String>('voice'));
      expect(voice, findsOneWidget);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(voice),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final Finder recordingBar = find.byType(VoiceMessageRecordingBar);
      expect(recordingBar, findsOneWidget);
      expect(
        tester.getRect(recordingBar).height,
        closeTo(
          VoiceMessageRecordingBar.heightFor(
            StarButtonSize.compact,
            touchPrimary: false,
          ),
          1,
        ),
      );

      await gesture.up();
      await tester.pump();
      await releaseTestWidgetTree(tester);
    });
  });
}
