import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/audio/chat_attachment/chat_attachment_audio_controller.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/voice_message_player.dart';
import 'package:star_app/features/chat/utils/attachments/attachment_display_utils.dart';
import 'package:star_app/features/chat/utils/media/media_proxy_url.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/gestures/nested_horizontal_scrollable.dart';
import 'package:star_app/shared/widgets/playback_seek_gesture_target.dart';

import '../../../../../helpers/test_l10n.dart';

const Attachment _attachment = Attachment(
  id: 'attachment-voice',
  url: 'https://cdn.example/voice.wav',
  filename: 'voice-message.wav',
  contentType: 'audio/wav',
  size: 2048,
  duration: 12,
);

String get _sourceUrl =>
    buildMediaProxyUrl(attachmentEffectiveUrl(_attachment));

Widget _app() {
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
    home: const Scaffold(body: VoiceMessagePlayer(attachment: _attachment)),
  );
}

void _startPlaying() {
  ChatAttachmentAudioController(
    sourceUrl: _sourceUrl,
    attachment: _attachment,
    title: () => _attachment.filename,
  ).debugSetPlaying();
}

void main() {
  tearDown(ChatAttachmentAudioController.resetForTest);

  testWidgets('disables seek while the voice message is idle', (tester) async {
    await tester.pumpWidget(_app());

    final PlaybackSeekGestureTarget seekTarget = tester
        .widget<PlaybackSeekGestureTarget>(
          find.byType(PlaybackSeekGestureTarget),
        );
    expect(seekTarget.enabled, isFalse);
    expect(find.byKey(kPlaybackSeekShellGestureBlockKey), findsNothing);
  });

  testWidgets('enables seek while the voice message is playing', (
    tester,
  ) async {
    _startPlaying();
    await tester.pumpWidget(_app());

    final PlaybackSeekGestureTarget seekTarget = tester
        .widget<PlaybackSeekGestureTarget>(
          find.byType(PlaybackSeekGestureTarget),
        );
    expect(seekTarget.enabled, isTrue);
    expect(find.byKey(kPlaybackSeekShellGestureBlockKey), findsOneWidget);
  });

  testWidgets('keeps playing after the player widget remounts', (tester) async {
    _startPlaying();
    await tester.pumpWidget(_app());
    expect(
      tester
          .widget<PlaybackSeekGestureTarget>(
            find.byType(PlaybackSeekGestureTarget),
          )
          .enabled,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      ChatAttachmentAudioController.debugContainsSource(_sourceUrl),
      isTrue,
    );

    await tester.pumpWidget(_app());
    expect(
      tester
          .widget<PlaybackSeekGestureTarget>(
            find.byType(PlaybackSeekGestureTarget),
          )
          .enabled,
      isTrue,
    );
  });
}
