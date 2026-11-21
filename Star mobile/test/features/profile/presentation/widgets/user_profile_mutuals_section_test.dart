import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/friends/domain/friend.dart';
import 'package:star_app/features/friends/providers/friend_providers.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_mutual_list.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_mutuals_section.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

import '../../../../helpers/test_l10n.dart';

Widget _buildApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: [
      friendsListProvider.overrideWith(
        (ref) => Stream<List<Friend>>.value(const <Friend>[]),
      ),
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
      home: Scaffold(body: child),
    ),
  );
}

UserPartialResponse _buildUser({
  required String id,
  required String username,
  String? globalName,
}) {
  return UserPartialResponse(
    id: id,
    username: username,
    discriminator: '1234',
    globalName: globalName,
    avatar: null,
    avatarColor: null,
    flags: 0,
  );
}

void main() {
  group('UserProfileMutualsSection', () {
    testWidgets('renders mutual count rows', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          UserProfileMutualsSection(
            friends: <UserPartialResponse>[
              _buildUser(id: '1', username: 'alice'),
              _buildUser(id: '2', username: 'bob'),
            ],
            communities: const <UserProfileFullResponseMutualGuilds>[
              UserProfileFullResponseMutualGuilds(id: '10', nick: null),
            ],
            onFriendTap: (_) {},
            onCommunityTap: (_) {},
          ),
        ),
      );

      expect(find.text('Mutual friends (2)'), findsOneWidget);
      expect(find.text('Mutual communities (1)'), findsOneWidget);
    });

    testWidgets('opens friend list bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          UserProfileMutualsSection(
            friends: <UserPartialResponse>[
              _buildUser(id: '1', username: 'alice', globalName: 'Alice'),
            ],
            communities: const <UserProfileFullResponseMutualGuilds>[],
            onFriendTap: (_) {},
            onCommunityTap: (_) {},
          ),
        ),
      );

      await tester.tap(find.text('Mutual friends (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Mutual friends'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice#1234'), findsOneWidget);
    });
  });

  group('UserProfileMutualList', () {
    testWidgets('renders friends empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          UserProfileMutualList(
            type: UserProfileMutualListType.friends,
            friends: const <UserPartialResponse>[],
            communities: const <UserProfileFullResponseMutualGuilds>[],
            onFriendTap: (_) {},
            onCommunityTap: (_) {},
          ),
        ),
      );

      expect(find.text('No mutual friends found.'), findsOneWidget);
    });

    testWidgets('renders communities empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildApp(
          UserProfileMutualList(
            type: UserProfileMutualListType.communities,
            friends: const <UserPartialResponse>[],
            communities: const <UserProfileFullResponseMutualGuilds>[],
            onFriendTap: (_) {},
            onCommunityTap: (_) {},
          ),
        ),
      );

      expect(find.text('No mutual communities found.'), findsOneWidget);
    });
  });
}
