import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/audio/chat_attachment/chat_attachment_audio_controller.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/attachments/attachment_audio.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/gestures/nested_horizontal_scrollable.dart';
import 'package:star_app/shared/widgets/playback_seek_gesture_target.dart';

import '../../../../../helpers/test_l10n.dart';

const Attachment _attachment = Attachment(
  id: 'attachment-audio',
  url: 'https://cdn.example/clip.mp3',
  filename: 'clip.mp3',
  contentType: 'audio/mpeg',
  size: 1024,
);

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
    home: const Scaffold(body: AttachmentAudio(attachment: _attachment)),
  );
}

void main() {
  tearDown(ChatAttachmentAudioController.resetForTest);

  testWidgets('disables seek while audio is idle', (tester) async {
    await tester.pumpWidget(_app());

    final PlaybackSeekGestureTarget seekTarget = tester
        .widget<PlaybackSeekGestureTarget>(
          find.byType(PlaybackSeekGestureTarget),
        );
    expect(seekTarget.enabled, isFalse);
    expect(find.byKey(kPlaybackSeekShellGestureBlockKey), findsNothing);
  });

  testWidgets('enables seek while audio is playing', (tester) async {
    ChatAttachmentAudioController(
      sourceUrl: _attachment.url,
      attachment: _attachment,
      title: () => _attachment.filename,
    ).debugSetPlaying();

    await tester.pumpWidget(_app());

    final PlaybackSeekGestureTarget seekTarget = tester
        .widget<PlaybackSeekGestureTarget>(
          find.byType(PlaybackSeekGestureTarget),
        );
    expect(seekTarget.enabled, isTrue);
    expect(find.byKey(kPlaybackSeekShellGestureBlockKey), findsOneWidget);
  });
}
