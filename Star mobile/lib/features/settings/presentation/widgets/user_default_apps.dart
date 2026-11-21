import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/default_web_browser.dart';
import 'package:star_app/features/settings/presentation/widgets/default_web_browser_icon.dart';
import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/settings/providers/preferences/default_apps_preferences_provider.dart';
import 'package:star_app/features/settings/utils/default_web_browser_l10n.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UserDefaultApps extends ConsumerWidget {
  const UserDefaultApps({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final DefaultWebBrowser selectedBrowser = ref.watch(
      defaultAppsPreferencesProvider,
    );
    final browsers = availableDefaultWebBrowsers();

    return SingleChildScrollView(
      controller: scrollController,
      padding: settingsScrollPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarSettingsSection(
            title: l10n.defaultAppsWebBrowserSectionTitle,
            description: l10n.defaultAppsWebBrowserSectionDescription,
            isFirst: true,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: l10n.defaultAppsWebBrowserSectionTitle,
                    container: true,
                    child: StarRadioGroup<DefaultWebBrowser>(
                      value: selectedBrowser,
                      onChanged: (DefaultWebBrowser value) => unawaited(
                        ref
                            .read(defaultAppsPreferencesProvider.notifier)
                            .setDefaultWebBrowser(value),
                      ),
                      items: [
                        for (final DefaultWebBrowser browser in browsers)
                          StarRadioItem(
                            value: browser,
                            label: defaultWebBrowserLabel(l10n, browser),
                            leading: DefaultWebBrowserIcon(browser: browser),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: layout.s1_5),
                  Text(
                    l10n.defaultAppsWebBrowserNativeAppNote,
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
