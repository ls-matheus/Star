import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/profile/providers/user_presence_provider.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/avatar/star_avatar_cluster.dart';
import 'package:star_app/features/ui/avatar/star_avatar_status_badge.dart';
import 'package:star_app/features/ui/status_indicator/star_mobile_online_status_indicator.dart';
import 'package:star_app/features/ui/status_indicator/star_status_indicator.dart';
import 'package:star_app/features/ui/status_indicator/star_typing_status_indicator.dart';
import 'package:star_app/material_ui.dart';

Widget buildTestApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    theme: buildStarTheme(
      colorTheme: colorTheme,
      textTheme: StarTextTheme.fromColors(colorTheme),
      layoutTheme: StarLayoutTheme.scaled(),
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('StarAvatar', () {
    testWidgets('user variant renders default avatar for user id', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '1',
            fallbackText: 'Alice',
            showStatus: false,
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.text('A'), findsNothing);
    });

    testWidgets('user variant never renders letter fallback', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: 'not-a-number',
            fallbackText: 'Alice',
            showStatus: false,
          ),
        ),
      );

      expect(find.text('A'), findsNothing);
      expect(find.text('?'), findsNothing);
    });

    testWidgets('user variant shows status indicator when status set', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '2',
            fallbackText: 'Bob',
            status: 'online',
          ),
        ),
      );

      expect(find.byType(StarStatusIndicator), findsOneWidget);
    });

    testWidgets('user variant shows phone indicator for mobile online', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '3',
            fallbackText: 'Bob',
            status: 'online',
            isMobileStatus: true,
            size: 32,
          ),
        ),
      );

      expect(find.byType(StarMobileOnlineStatusIndicator), findsOneWidget);
      expect(find.byType(StarStatusIndicator), findsNothing);
    });

    testWidgets('mobile idle status keeps round indicator', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '4',
            fallbackText: 'Bob',
            status: 'idle',
            isMobileStatus: true,
            size: 32,
          ),
        ),
      );

      expect(find.byType(StarStatusIndicator), findsOneWidget);
      expect(find.byType(StarMobileOnlineStatusIndicator), findsNothing);
    });

    testWidgets('user variant shows typing indicator when isTyping is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '5',
            fallbackText: 'Bob',
            status: 'online',
            isTyping: true,
          ),
        ),
      );

      expect(find.byType(StarTypingStatusIndicator), findsOneWidget);
      expect(find.byType(StarStatusIndicator), findsNothing);
    });

    testWidgets('typing indicator renders three dots', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarTypingStatusIndicator(
            status: 'online',
            width: 22,
            height: 12,
          ),
        ),
      );

      expect(find.byType(StarTypingStatusIndicator), findsOneWidget);
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('default constructor renders without status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarAvatar(fallbackText: 'Test')),
      );

      expect(find.text('T'), findsOneWidget);
      expect(find.byType(StarStatusIndicator), findsNothing);
    });

    testWidgets(
      'network image preserves aspect ratio in memory cache for cover fit',
      (tester) async {
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestApp(
            const StarAvatar.user(
              userId: '6',
              imageUrl: 'https://cdn.example/avatar.webp',
              fallbackText: 'Alice',
              showStatus: false,
            ),
          ),
        );

        final image = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(image.memCacheWidth, 120);
        expect(image.memCacheHeight, isNull);
        expect(image.fit, BoxFit.cover);
      },
    );

    testWidgets('skips memory cache resize for animated avatar urls', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '6',
            imageUrl:
                'https://cdn.example/avatars/6/a_avatar.gif?animated=true&size=80',
            fallbackText: 'Alice',
            showStatus: false,
          ),
        ),
      );

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.memCacheWidth, isNull);
      expect(image.memCacheHeight, isNull);
    });

    testWidgets('hides status when showStatus is false', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '7',
            fallbackText: 'Bob',
            status: 'online',
            showStatus: false,
          ),
        ),
      );

      expect(find.byType(StarStatusIndicator), findsNothing);
    });

    testWidgets('never draws status on avatars of 16pt or smaller', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '8',
            fallbackText: 'Bob',
            status: 'online',
            size: 16,
          ),
        ),
      );

      expect(find.byType(StarStatusIndicator), findsNothing);
    });

    testWidgets('keeps the image element when status arrives', (tester) async {
      Widget avatar(String? status) => buildTestApp(
        StarAvatar.user(
          userId: '9',
          imageUrl: 'https://cdn.example/avatar.webp',
          fallbackText: 'Bob',
          status: status,
          size: 32,
        ),
      );

      await tester.pumpWidget(avatar(null));
      final Element before = tester.element(find.byType(CachedNetworkImage));

      await tester.pumpWidget(avatar('online'));
      await tester.pumpAndSettle();

      expect(tester.element(find.byType(CachedNetworkImage)), same(before));
      expect(find.byType(StarStatusIndicator), findsOneWidget);
    });

    testWidgets('status dot grows in instead of popping', (tester) async {
      Widget avatar(String? status) => buildTestApp(
        Center(
          child: StarAvatar.user(
            userId: '10',
            fallbackText: 'Bob',
            status: status,
            size: 32,
          ),
        ),
      );

      await tester.pumpWidget(avatar(null));
      await tester.pumpWidget(avatar('online'));
      await tester.pump(kAvatarStatusTransitionDuration ~/ 4);
      final double mid = tester
          .getSize(find.byType(StarStatusIndicator))
          .width;
      await tester.pumpAndSettle();
      final double end = tester
          .getSize(find.byType(StarStatusIndicator))
          .width;

      expect(mid, greaterThan(0));
      expect(mid, lessThan(end));
      expect(end, 10);
    });

    testWidgets('dot sits flush with the bottom-right corner', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const Center(
            child: StarAvatar.user(
              userId: '11',
              fallbackText: 'Bob',
              status: 'online',
              size: 32,
            ),
          ),
        ),
      );

      final Rect avatar = tester.getRect(find.byType(StarAvatar));
      final Rect dot = tester.getRect(find.byType(StarStatusIndicator));
      expect(dot.size, const Size(10, 10));
      expect(dot.bottomRight, avatar.bottomRight);
    });

    testWidgets('loading avatars show a placeholder and keep the old image', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatar.user(
            userId: '12',
            imageUrl: 'https://cdn.example/avatar.webp',
            fallbackText: 'Bob',
            avatarColor: 0xFF123456,
          ),
        ),
      );

      final CachedNetworkImage image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.useOldImageOnUrlChange, isTrue);
      expect(image.fadeInDuration, Duration.zero);
      expect(image.placeholder, isNotNull);
    });

    testWidgets('presence avatar shows the status from the presence store', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userPresenceProvider('13').overrideWithBuild(
              (Ref ref, UserPresenceNotifier notifier) =>
                  const UserPresence(status: 'idle'),
            ),
          ],
          child: buildTestApp(
            StarAvatar.userPresence(userId: '13', fallbackText: 'Bob'),
          ),
        ),
      );

      expect(
        tester
            .widget<StarStatusIndicator>(find.byType(StarStatusIndicator))
            .status,
        'idle',
      );
    });

    testWidgets('group clusters never show presence, only typing', (
      tester,
    ) async {
      const List<AvatarClusterMember> members = [
        AvatarClusterMember(userId: '1'),
        AvatarClusterMember(userId: '2'),
      ];
      await tester.pumpWidget(
        buildTestApp(const StarAvatarCluster(members: members)),
      );
      expect(find.byType(StarStatusIndicator), findsNothing);
      expect(find.byType(StarTypingStatusIndicator), findsNothing);

      await tester.pumpWidget(
        buildTestApp(
          const StarAvatarCluster(members: members, isTyping: true),
        ),
      );
      await tester.pump(kAvatarStatusTransitionDuration);
      expect(find.byType(StarTypingStatusIndicator), findsOneWidget);
      expect(find.byType(StarStatusIndicator), findsNothing);
    });

    testWidgets('typing cutout keeps the back circle of a group stack whole', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const Center(
            child: StarAvatarCluster(
              members: [
                AvatarClusterMember(userId: '1'),
                AvatarClusterMember(userId: '2'),
              ],
              isTyping: true,
            ),
          ),
        ),
      );
      final ClipPath clip = tester.widget<ClipPath>(
        find
            .descendant(
              of: find.byType(StarAvatarStatusBadge),
              matching: find.byType(ClipPath),
            )
            .first,
      );
      final Path path = clip.clipper!.getClip(const Size.square(32));
      expect(path.contains(const Offset(3.5, 3.5)), isTrue);
      expect(path.contains(const Offset(28, 28)), isFalse);
    });

    testWidgets('avatar cluster tolerates non-numeric member ids', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatarCluster(
            members: [
              AvatarClusterMember(userId: 'oops'),
              AvatarClusterMember(userId: '2'),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('StarAvatarCluster', () {
    testWidgets('stacks two 20pt circles at the corners of a 32pt box', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const Center(
            child: StarAvatarCluster(
              members: [
                AvatarClusterMember(userId: '1'),
                AvatarClusterMember(userId: '2'),
                AvatarClusterMember(userId: '3'),
              ],
            ),
          ),
        ),
      );

      final Rect box = tester.getRect(find.byType(StarAvatarCluster));
      expect(box.size, const Size(32, 32));
      final List<Rect> circles = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map(
            (CachedNetworkImage image) =>
                tester.getRect(find.byWidget(image)).shift(-box.topLeft),
          )
          .toList();
      expect(circles, const <Rect>[
        Rect.fromLTWH(0, 0, 20, 20),
        Rect.fromLTWH(12, 12, 20, 20),
      ]);
    });

    testWidgets('never shows a status dot', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatarCluster(
            members: [
              AvatarClusterMember(userId: '1'),
              AvatarClusterMember(userId: '2'),
            ],
          ),
        ),
      );

      expect(find.byType(StarStatusIndicator), findsNothing);
      expect(find.byType(StarTypingStatusIndicator), findsNothing);
      expect(find.byType(StarMobileOnlineStatusIndicator), findsNothing);
    });

    testWidgets('cuts a transparent ring out of the back avatar', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const Center(
            child: StarAvatarCluster(
              members: [
                AvatarClusterMember(userId: '1'),
                AvatarClusterMember(userId: '2'),
              ],
            ),
          ),
        ),
      );

      final ClipPath clip = tester.widget<ClipPath>(
        find.descendant(
          of: find.byType(Positioned).first,
          matching: find.byType(ClipPath),
        ),
      );
      final Path path = clip.clipper!.getClip(const Size(20, 20));
      expect(path.contains(const Offset(4, 4)), isTrue);
      expect(path.contains(const Offset(12.5, 12.5)), isTrue);
      expect(path.contains(const Offset(13.5, 13.5)), isFalse);
      expect(path.contains(const Offset(16, 16)), isFalse);
    });

    testWidgets('falls back to a brand glyph disc without members', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatarCluster(
            members: [AvatarClusterMember(userId: '1')],
          ),
        ),
      );

      final Container disc = tester.widget<Container>(
        find.descendant(
          of: find.byType(StarAvatarCluster),
          matching: find.byType(Container),
        ),
      );
      expect(
        (disc.decoration! as BoxDecoration).color,
        buildDarkColorTheme().brandPrimary,
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('custom icon renders instead of the member stack', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const StarAvatarCluster(
            iconUrl: 'https://cdn.example/icons/9/icon.webp',
            members: [
              AvatarClusterMember(userId: '1'),
              AvatarClusterMember(userId: '2'),
            ],
          ),
        ),
      );

      final CachedNetworkImage image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://cdn.example/icons/9/icon.webp');
      expect(image.fadeInDuration, Duration.zero);
      expect(image.memCacheWidth, isNotNull);
    });
  });

  group('StarStatusPainter', () {
    const Rect bounds = Rect.fromLTWH(0, 0, 10, 10);

    test('online is a solid disc', () {
      final Path path = StarStatusPainter.glyphPath('online', bounds);
      expect(path.contains(bounds.center), isTrue);
    });

    test('offline punches a transparent hole about 4.7pt wide', () {
      final Path path = StarStatusPainter.glyphPath('offline', bounds);
      expect(path.contains(bounds.center), isFalse);
      expect(path.contains(bounds.center + const Offset(2.2, 0)), isFalse);
      expect(path.contains(bounds.center + const Offset(3.6, 0)), isTrue);
    });

    test('idle bites the top-left out of the disc', () {
      final Path path = StarStatusPainter.glyphPath('idle', bounds);
      expect(path.contains(const Offset(3, 3)), isFalse);
      expect(path.contains(const Offset(7, 7)), isTrue);
    });

    test('dnd cuts a transparent bar through the centre', () {
      final Path path = StarStatusPainter.glyphPath('dnd', bounds);
      expect(path.contains(bounds.center), isFalse);
      expect(path.contains(const Offset(5, 2)), isTrue);
    });
  });

  group('StarStatusIndicator', () {
    testWidgets('shows correct color for online status', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const StarStatusIndicator(status: 'online')),
      );

      final indicator = tester.widget<StarStatusIndicator>(
        find.byType(StarStatusIndicator),
      );
      expect(indicator.status, 'online');

      expect(
        tester.getSize(find.byType(StarStatusIndicator)),
        const Size(15, 15),
      );
    });

    testWidgets('renders all status variants without error', (tester) async {
      for (final status in ['online', 'idle', 'dnd', 'streaming', 'offline']) {
        await tester.pumpWidget(
          buildTestApp(StarStatusIndicator(status: status)),
        );
        expect(find.byType(StarStatusIndicator), findsOneWidget);
      }
    });
  });
}
