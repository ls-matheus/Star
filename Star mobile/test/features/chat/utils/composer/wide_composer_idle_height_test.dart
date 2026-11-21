import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/voice_message_recording_bar.dart';
import 'package:star_app/features/chat/presentation/widgets/composer/wide_composer_layout.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';

double wideComposerIdleSlotHeight(
  StarButtonSize actionSize, {
  required bool touchPrimary,
}) {
  return WideComposerLayout.densePaddingYFor(touchPrimary: touchPrimary) * 2 +
      actionSize.height;
}

void main() {
  group('wide composer idle vs recording slot height', () {
    for (final (StarButtonSize actionSize, bool touchPrimary)
        in <(StarButtonSize, bool)>[
          (StarButtonSize.compact, false),
          (StarButtonSize.small, true),
        ]) {
      test('${actionSize.name} idle padded slot matches recording bar', () {
        expect(
          wideComposerIdleSlotHeight(actionSize, touchPrimary: touchPrimary),
          VoiceMessageRecordingBar.heightFor(
            actionSize,
            touchPrimary: touchPrimary,
          ),
        );
      });
    }

    test('mouse box fills the floating box min height exactly', () {
      expect(
        wideComposerIdleSlotHeight(
              StarButtonSize.compact,
              touchPrimary: false,
            ) +
            WideComposerLayout.ringWidth * 2,
        WideComposerLayout.boxMinHeight,
      );
    });
  });
}
