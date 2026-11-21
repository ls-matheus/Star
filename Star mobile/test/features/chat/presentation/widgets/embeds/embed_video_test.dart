import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/presentation/widgets/embeds/embed_shared.dart';
import 'package:star_app/features/chat/presentation/widgets/embeds/embed_video.dart';
import 'package:star_app/features/chat/presentation/widgets/media/chat_inline_video_player.dart';
import 'package:star_app/material_ui.dart';

import '../../../../../helpers/core_test_provider_overrides.dart';
import '../../../../../helpers/test_l10n.dart';

Widget _wrap(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: coreTestProviderOverrides(),
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

bool _hasEmbedChrome(WidgetTester tester) {
  return tester.widgetList<Container>(find.byType(Container)).any((
    Container container,
  ) {
    final Decoration? decoration = container.decoration;
    if (decoration is! BoxDecoration) {
      return false;
    }
    final BoxBorder? border = decoration.border;
    return border is BorderDirectional && border.start.width == 4;
  });
}

void main() {
  testWidgets('media-only video embed looks like an uploaded video', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const EmbedVideo(
          embed: Embed(
            type: EmbedType.video,
            url: 'https://cdn.star.invalid/attachments/1/2/clip.mp4',
            video: EmbedMedia(
              url: 'https://cdn.star.invalid/attachments/1/2/clip.mp4',
              proxyUrl: 'https://cdn.star.invalid/attachments/1/2/clip.mp4',
              width: 1280,
              height: 720,
            ),
          ),
          channelId: 'c1',
          embedIndex: 0,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ChatInlineVideoPlayer), findsOneWidget);
    expect(find.byType(EmbedTitle), findsNothing);
    expect(_hasEmbedChrome(tester), isFalse);
  });

  testWidgets('rich video embed keeps embed chrome and title', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EmbedVideo(
          embed: Embed(
            type: EmbedType.video,
            url: 'https://www.youtube.com/watch?v=abc',
            providerName: 'YouTube',
            providerUrl: 'https://www.youtube.com',
            title: 'A clip',
            video: EmbedMedia(
              url: 'https://www.youtube.com/embed/abc',
              proxyUrl: 'https://proxy.example.com/video',
              width: 1280,
              height: 720,
            ),
          ),
          channelId: 'c1',
          embedIndex: 0,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(EmbedTitle), findsOneWidget);
    expect(_hasEmbedChrome(tester), isTrue);
  });
}
