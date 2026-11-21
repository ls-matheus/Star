import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/providers/database_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/members/presentation/widgets/member_list_member_row.dart';
import 'package:star_app/features/members/presentation/widgets/member_list_shared_widgets.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/status_indicator/star_status_indicator.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';
import 'package:star_dart/gateway.dart';

import '../../../../helpers/open_test_database.dart';

GuildMemberResponse _member(String userId) => GuildMemberResponse(
  user: UserPartialResponse(
    id: userId,
    username: 'user-$userId',
    discriminator: '0001',
    globalName: null,
    avatar: null,
    avatarColor: null,
    flags: 0,
  ),
  roles: const <String>[],
  joinedAt: DateTime.utc(2024),
  mute: false,
  deaf: false,
);

Widget _app(Widget child) {
  final colorTheme = buildDarkColorTheme();
  final overrides = <Override>[
    starDatabaseProvider.overrideWithValue(openTestDatabase()),
  ];
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('sidebar member rows show the offline dot', (tester) async {
    await tester.pumpWidget(
      _app(
        MemberListSidebarMemberRow(
          guildId: '1',
          channelId: '2',
          userId: '3',
          rolesById: const {},
          listMember: MemberListMember(member: _member('3'), status: 'offline'),
        ),
      ),
    );
    await tester.pump();

    final StarAvatar avatar = tester.widget<StarAvatar>(
      find.byType(StarAvatar),
    );
    expect(avatar.showStatus, isTrue);
    expect(avatar.status, 'offline');
    expect(
      tester
          .widget<StarStatusIndicator>(find.byType(StarStatusIndicator))
          .status,
      'offline',
    );
    await releaseTestWidgetTree(tester);
  });

  testWidgets('details member row press highlight follows the group corners', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        MemberListDetailsMemberShell(
          isFirstInGroup: true,
          isLastInGroup: false,
          child: MemberListDetailsMemberRow(
            guildId: '1',
            userId: '3',
            rolesById: const {},
            dimmed: false,
            listMember: MemberListMember(
              member: _member('3'),
              status: 'online',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder clip = find.ancestor(
      of: find.byType(InkWell),
      matching: find.byType(ClipRRect),
    );
    expect(clip, findsOneWidget);
    expect(
      tester.widget<ClipRRect>(clip).borderRadius,
      const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
    );
    await releaseTestWidgetTree(tester);
  });
}
