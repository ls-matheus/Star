import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/discovery/presentation/widgets/discovery_header.dart';
import 'package:star_app/features/discovery/presentation/widgets/discovery_sidebar.dart';
import 'package:star_app/material_ui.dart';

class DiscoverySidebarColumn extends StatelessWidget {
  const DiscoverySidebarColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.channelSidebarBackground,
      child: const SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DiscoveryHeader(),
            Expanded(child: DiscoverySidebar()),
          ],
        ),
      ),
    );
  }
}
