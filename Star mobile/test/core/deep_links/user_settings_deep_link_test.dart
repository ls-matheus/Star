import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/deep_links/user_settings_deep_link.dart';
import 'package:star_app/features/settings/domain/user_settings_section.dart';
import 'package:star_app/features/settings/utils/user_settings/open_user_settings_deep_link.dart';
import 'package:star_app/l10n/star_localizations_delegates.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

void main() {
  Uri uri(String path) => Uri.parse('https://web.star.invalid$path');

  group('parseUserSettingsDeepLink', () {
    test('returns null for non-settings paths', () {
      expect(parseUserSettingsDeepLink(uri('/channels/@me')), isNull);
    });

    test('opens settings root when tab is missing or invalid', () {
      expect(parseUserSettingsDeepLink(uri('/settings/user'))?.section, isNull);
      expect(
        parseUserSettingsDeepLink(
          uri('/settings/user?tab=unknown_tab'),
        )?.section,
        isNull,
      );
      expect(
        parseUserSettingsDeepLink(uri('/settings/user?tab=bad tab'))?.section,
        isNull,
      );
    });

    test('maps appearance tab to look and feel', () {
      final UserSettingsDeepLinkTarget? target = parseUserSettingsDeepLink(
        uri('/settings/user?tab=appearance'),
      );
      expect(target?.section, UserSettingsSection.lookAndFeel);
      expect(target?.tab, 'appearance');
      expect(target?.fieldId, isNull);
    });

    test('maps appearance theme section to look and feel with field id', () {
      final UserSettingsDeepLinkTarget? target = parseUserSettingsDeepLink(
        uri('/settings/user?tab=appearance&section=theme'),
      );
      expect(target?.section, UserSettingsSection.lookAndFeel);
      expect(target?.tab, 'appearance');
      expect(target?.fieldId, 'theme');
    });

    test('maps account security password section to security login', () {
      final UserSettingsDeepLinkTarget? target = parseUserSettingsDeepLink(
        uri('/settings/user?tab=account_security&section=password'),
      );
      expect(target?.section, UserSettingsSection.securityLogin);
      expect(target?.fieldId, 'password');
    });

    test('opens security login for unknown account security section', () {
      final UserSettingsDeepLinkTarget? target = parseUserSettingsDeepLink(
        uri('/settings/user?tab=account_security&section=not_real'),
      );
      expect(target?.section, UserSettingsSection.securityLogin);
      expect(target?.fieldId, isNull);
    });

    test('resolves nested authorized apps tab', () {
      expect(
        parseUserSettingsDeepLink(
          uri('/settings/user?tab=authorized_apps'),
        )?.section,
        UserSettingsSection.authorizedApps,
      );
    });

    test('resolves legacy authorized apps section under account security', () {
      expect(
        parseUserSettingsDeepLink(
          uri('/settings/user?tab=account_security&section=authorized_apps'),
        )?.section,
        UserSettingsSection.authorizedApps,
      );
    });

    test('unsupported tab has no section mapping', () {
      expect(isUserSettingsDeepLinkTabSupported('desktop_settings'), isFalse);
      expect(
        parseUserSettingsDeepLink(
          uri('/settings/user?tab=desktop_settings'),
        )?.section,
        isNull,
      );
    });
  });

  group('userSettingsDeepLinkTabLabel', () {
    testWidgets('unsupported tab uses generic user settings label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final label = userSettingsDeepLinkTabLabel(
                StarLocalizations.of(context),
                const UserSettingsDeepLinkTarget(tab: 'desktop_settings'),
              );
              expect(label, 'User settings');
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('plutonium tab uses instance premium page label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: starLocalizationsDelegates,
          supportedLocales: StarLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final label = userSettingsDeepLinkTabLabel(
                StarLocalizations.of(context),
                parseUserSettingsDeepLink(uri('/settings/user?tab=plutonium'))!,
                premiumProductName: 'Nitro',
              );
              expect(label, 'Nitro page');
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('buildUserSettingsDeepLink', () {
    test('builds appearance section links', () {
      expect(
        buildUserSettingsDeepLink('appearance', 'theme'),
        'star://settings/user?tab=appearance&section=theme',
      );
    });

    test('maps nested account tabs to account security', () {
      expect(
        buildUserSettingsDeepLink('authorized_apps'),
        'star://settings/user?tab=account_security&section=security',
      );
      expect(
        buildUserSettingsDeepLink('blocked_users'),
        'star://settings/user?tab=account_security&section=blocked_users',
      );
    });

    test('builds mobile-only settings page links', () {
      expect(
        buildUserSettingsDeepLink('default_apps'),
        'star://settings/user?tab=default_apps',
      );
      expect(
        buildUserSettingsDeepLink('app_icon'),
        'star://settings/user?tab=app_icon',
      );
    });
  });

  group('mapUserSettingsDeepLinkToSection', () {
    test('maps plutonium and gift inventory tabs', () {
      expect(
        mapUserSettingsDeepLinkToSection('plutonium', null),
        UserSettingsSection.starPlutonium,
      );
      expect(
        mapUserSettingsDeepLinkToSection('gift_inventory', null),
        UserSettingsSection.giftsAndCodes,
      );
    });

    test('returns null for unsupported web-only tabs', () {
      expect(
        mapUserSettingsDeepLinkToSection('desktop_settings', null),
        isNull,
      );
      expect(
        mapUserSettingsDeepLinkToSection('client_developer_settings', null),
        isNull,
      );
    });

    test('maps mobile-only settings tabs', () {
      expect(
        mapUserSettingsDeepLinkToSection('default_apps', null),
        UserSettingsSection.defaultApps,
      );
      expect(
        mapUserSettingsDeepLinkToSection('app_icon', null),
        UserSettingsSection.appIcon,
      );
      expect(
        parseUserSettingsDeepLink(
          uri('/settings/user?tab=default_apps'),
        )?.section,
        UserSettingsSection.defaultApps,
      );
      expect(
        parseUserSettingsDeepLink(uri('/settings/user?tab=app_icon'))?.section,
        UserSettingsSection.appIcon,
      );
    });
  });
}
