// Widget tests override family providers without listing every transitive dep.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/chat/presentation/widgets/messages/message_markdown.dart';
import 'package:star_app/features/chat/providers/pickers/emoji_picker_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/emoji/emoji_registry.dart';
import 'package:star_markdown/star_markdown.dart';

import '../../../../../helpers/core_test_provider_overrides.dart';
import '../../../../../helpers/open_test_database.dart';

const String _body = 'hi \u{1F600} \u{1F44B}\u{1F3FD} \u2764\uFE0F';

Widget _app({
  required Future<void> registryLoaded,
  required ValueListenable<bool> show,
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: coreTestProviderOverrides(
      extra: [
        emojiRegistryLoadedProvider.overrideWith((ref) => registryLoaded),
      ],
    ),
    child: MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        StarLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: show,
          builder: (BuildContext context, bool visible, Widget? child) =>
              visible
              ? const MessageMarkdown(data: _body, messageId: 'm1')
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'messages rendered before the emoji registry loads switch to Twemoji',
    (WidgetTester tester) async {
      expect(EmojiRegistry.unicodeEmojiMatcherSync, isNull);
      final registryLoaded = Completer<void>();
      final show = ValueNotifier<bool>(true);
      addTearDown(show.dispose);

      await tester.pumpWidget(
        _app(registryLoaded: registryLoaded.future, show: show),
      );
      expect(find.byType(CachedEmojiAssetImage), findsNothing);

      show.value = false;
      await tester.pump();
      show.value = true;
      await tester.pump();

      await tester.runAsync(EmojiRegistry.preload);
      registryLoaded.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CachedEmojiAssetImage), findsNWidgets(3));

      show.value = false;
      await tester.pump();
      show.value = true;
      await tester.pump();
      expect(find.byType(CachedEmojiAssetImage), findsNWidgets(3));
      await releaseTestWidgetTree(tester);
    },
  );
}
