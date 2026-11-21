// Root ProviderScope built by a helper; the lint only exempts a
// ProviderScope written inline in pumpWidget.
// ignore_for_file: riverpod_lint/scoped_providers_should_specify_dependencies

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/profile/presentation/widgets/user_profile_badges.dart';
import 'package:star_app/features/profile/utils/profile_badge_media.dart';
import 'package:star_app/features/ui/toast/star_toast_overlay.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

import '../../../../helpers/test_l10n.dart';

Widget _buildApp(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    child: MaterialApp(
      locale: kTestLocale,
      localizationsDelegates: starLocalizationsDelegates,
      supportedLocales: StarLocalizations.supportedLocales,
      theme: buildStarTheme(
        colorTheme: colorTheme,
        textTheme: StarTextTheme.fromColors(colorTheme),
        layoutTheme: StarLayoutTheme.scaled(),
      ),
      home: StarToastOverlay(
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

ProfileBadgeResponse _badge({
  required String kind,
  String? asset,
  String? caption,
  String label = 'Badge label',
}) {
  return ProfileBadgeResponse(
    key: kind,
    kind: kind,
    label: label,
    asset: asset,
    assetUrl: null,
    aspectRatio: null,
    caption: caption,
    href: null,
  );
}

void main() {
  group('UserProfileBadges', () {
    testWidgets('renders nothing for empty badges', (tester) async {
      await tester.pumpWidget(_buildApp(const UserProfileBadges(badges: [])));
      expect(find.byType(UserProfileBadges), findsOneWidget);
      expect(find.text('Badge label'), findsNothing);
    });

    testWidgets('renders caption badge text', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          UserProfileBadges(
            badges: <ProfileBadgeResponse>[
              _badge(kind: 'visionary_number', caption: '#42'),
            ],
          ),
        ),
      );
      expect(find.text('#42'), findsOneWidget);
    });

    test('hasBadges reflects list length', () {
      expect(UserProfileBadges.hasBadges([]), isFalse);
      expect(
        UserProfileBadges.hasBadges(<ProfileBadgeResponse>[
          _badge(kind: 'staff', asset: 'abc'),
        ]),
        isTrue,
      );
    });

    testWidgets('shows overflow control when maxVisible exceeded', (
      tester,
    ) async {
      final List<ProfileBadgeResponse> many =
          List<ProfileBadgeResponse>.generate(
            8,
            (int i) => _badge(kind: 'custom_$i', asset: 'abc$i'),
          );
      await tester.pumpWidget(
        _buildApp(
          UserProfileBadges(
            badges: many,
            maxVisible: kProfileBadgesCompactMaxVisible,
          ),
        ),
      );
      expect(find.text('+1'), findsOneWidget);
    });
  });
}
