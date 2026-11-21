import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/discovery/presentation/discovery_page.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/root_overlay_back_scope.dart';
import 'package:star_app/material_ui.dart';

class DiscoveryLayout extends StatelessWidget {
  const DiscoveryLayout({super.key});

  @override
  Widget build(BuildContext context) {
    const Widget page = DiscoveryPage();
    if (!isMobileLayout(context)) {
      return page;
    }
    return RootOverlayBackScope(
      child: Scaffold(
        backgroundColor: context.colors.backgroundPrimary,
        body: page,
      ),
    );
  }
}
