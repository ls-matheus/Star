import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/default_web_browser.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class DefaultWebBrowserIcon extends StatelessWidget {
  const DefaultWebBrowserIcon({required this.browser, super.key});

  static const Size size = Size(24, 35);

  final DefaultWebBrowser browser;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Center(child: _buildIcon(context)),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return switch (browser) {
      DefaultWebBrowser.inApp => PhosphorIcon(
        PhosphorIconsFill.browser,
        size: 22,
        color: context.colors.textPrimary,
      ),
      DefaultWebBrowser.external => PhosphorIcon(
        PhosphorIconsFill.globe,
        size: 22,
        color: context.colors.textPrimary,
      ),
      DefaultWebBrowser.safari ||
      DefaultWebBrowser.chrome ||
      DefaultWebBrowser.firefox ||
      DefaultWebBrowser.duckDuckGo ||
      DefaultWebBrowser.qwant => PhosphorIcon(
        PhosphorIconsFill.globeSimple,
        size: 22,
        color: context.colors.textPrimary,
      ),
    };
  }
}
