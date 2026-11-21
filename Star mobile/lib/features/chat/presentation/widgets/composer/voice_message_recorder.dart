import 'dart:async';

import 'package:star_app/features/chat/presentation/widgets/composer/voice_message_recording_controller.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class VoiceMessageRecorder extends StatefulWidget {
  const VoiceMessageRecorder({
    required this.channelId,
    required this.disabled,
    required this.controller,
    this.holdToRecord = true,
    this.buttonSize = StarButtonSize.compact,
    this.restingChild,
    super.key,
  });

  final String channelId;
  final bool disabled;
  final VoiceMessageRecordingController controller;
  final bool holdToRecord;
  final StarButtonSize buttonSize;
  final Widget? restingChild;

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> {
  @override
  void didUpdateWidget(covariant VoiceMessageRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled &&
        (widget.controller.isArming || widget.controller.isRecording) &&
        !widget.controller.isSending) {
      unawaited(widget.controller.discardIfDisabled());
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.disabled ||
        widget.controller.isSending ||
        widget.controller.isActive) {
      return;
    }
    if (widget.holdToRecord) {
      unawaited(
        widget.controller.startHold(
          context: context,
          channelId: widget.channelId,
          event: event,
        ),
      );
      return;
    }
    unawaited(
      widget.controller.startLocked(
        context: context,
        channelId: widget.channelId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, Widget? _) {
        final bool recording = widget.controller.isActive;
        return Semantics(
          label: l10n.voiceMessageTitle,
          hint: widget.holdToRecord ? l10n.voiceMessageHoldHint : null,
          button: true,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: widget.disabled ? null : _handlePointerDown,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: recording
                    ? StarButton.circle(
                        icon: PhosphorIconsFill.microphone,
                        semanticLabel: l10n.voiceMessageTitle,
                        size: widget.buttonSize,
                        iconSize: 20,
                        onPressed: widget.disabled ? null : () {},
                      )
                    : widget.restingChild ??
                          StarButton.circleAlt(
                            icon: PhosphorIconsFill.microphone,
                            semanticLabel: l10n.voiceMessageTitle,
                            size: widget.buttonSize,
                            onPressed: widget.disabled ? null : () {},
                          ),
              ),
            ),
          ),
        );
      },
    );
  }
}
