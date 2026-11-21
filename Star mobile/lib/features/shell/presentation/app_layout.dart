import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:star_app/features/input/presentation/keybind_scope.dart';
import 'package:star_app/features/shell/presentation/mobile_shell_scaffold.dart';
import 'package:star_app/features/shell/presentation/shell_route_listeners.dart';
import 'package:star_app/features/shell/presentation/splash_shell_settle.dart';
import 'package:star_app/material_ui.dart';
import 'package:go_router/go_router.dart';

class AppLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppLayout({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShellRouteListeners(
      child: SplashShellSettle(
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            KeybindScope(
              child: AppLayoutShell(navigationShell: navigationShell),
            ),
            const ChannelIconPrewarm(),
          ],
        ),
      ),
    );
  }
}
