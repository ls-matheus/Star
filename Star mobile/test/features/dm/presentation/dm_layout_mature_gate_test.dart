import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/database/star_database.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/channel_chat_content.dart';
import 'package:star_app/features/chat/presentation/widgets/channel/channel_header.dart';
import 'package:star_app/features/dm/presentation/dm_layout.dart';
import 'package:star_app/features/mature_content/domain/mature_content_types.dart';
import 'package:star_app/features/mature_content/presentation/widgets/mature_content_channel_gate.dart';
import 'package:star_app/features/mature_content/providers/mature_content_agreements_provider.dart';
import 'package:star_app/features/mature_content/providers/sensitive_content_provider.dart';
import 'package:star_app/material_ui.dart' hide SensitiveContent;

import '../../../helpers/open_test_database.dart';
import '../../../helpers/test_l10n.dart';

class _AppLockedSensitive extends SensitiveContent {
  @override
  SensitiveContentState build() =>
      const SensitiveContentState(access: MatureAccess.appLocked);
}

void main() {
  testWidgets('an 18+ group DM opened by route shows the iOS lock', (
    WidgetTester tester,
  ) async {
    final StarDatabase database = openTestDatabase();
    await database.dmChannelDao.upsertDmChannels(<DmChannelsCompanion>[
      DmChannelsCompanion.insert(
        id: 'group-1',
        recipientId: '',
        type: Value<int>(ChannelType.groupDm.wireValue),
        nsfw: const Value<bool>(true),
      ),
    ]);
    final colorTheme = buildDarkColorTheme();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          starDatabaseProvider.overrideWithValue(database),
          sensitiveContentProvider.overrideWith(_AppLockedSensitive.new),
          matureGateContextProvider('group-1').overrideWith((ref) => null),
        ],
        child: MaterialApp(
          locale: kTestLocale,
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          theme: buildStarTheme(
            colorTheme: colorTheme,
            textTheme: StarTextTheme.fromColors(colorTheme),
            layoutTheme: StarLayoutTheme.scaled(),
          ),
          home: const Scaffold(body: DMLayout(channelId: 'group-1')),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ChannelChatContent), findsNothing);
    await tester.pumpAndSettle();

    expect(find.byType(MatureContentChannelGate), findsOneWidget);
    expect(find.byType(ChannelChatContent), findsNothing);
    expect(
      find.textContaining('18+ content is off on iPhone and iPad'),
      findsOneWidget,
    );
    expect(find.text('Proceed'), findsNothing);
    expect(find.byType(ChannelHeader), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(MatureContentChannelGate),
        matching: find.byWidgetPredicate(
          (Widget widget) => widget is ColoredBox && widget.color.a == 1,
        ),
      ),
      findsWidgets,
    );

    await releaseTestWidgetTree(tester);
  });
}
