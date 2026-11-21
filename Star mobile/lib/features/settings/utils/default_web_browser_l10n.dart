import 'package:star_app/features/settings/domain/default_web_browser.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String defaultWebBrowserLabel(
  StarLocalizations l10n,
  DefaultWebBrowser browser,
) {
  return switch (browser) {
    DefaultWebBrowser.inApp => l10n.defaultAppsWebBrowserInApp,
    DefaultWebBrowser.external => l10n.defaultAppsWebBrowserExternal,
    DefaultWebBrowser.qwant => 'Qwant',
    DefaultWebBrowser.safari => 'Safari',
    DefaultWebBrowser.duckDuckGo => 'DuckDuckGo',
    DefaultWebBrowser.firefox => 'Firefox',
    DefaultWebBrowser.chrome => 'Chrome',
  };
}
