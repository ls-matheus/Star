import 'package:star_app/features/settings/presentation/widgets/wide_settings_content_layout.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';
import 'package:go_router/go_router.dart';

class WideSettingsModalOverlay extends StatelessWidget {
  const WideSettingsModalOverlay({
    required this.child,
    this.maxModalWidth = kWideSettingsModalMaxWidth,
    super.key,
  });

  final Widget child;
  final double maxModalWidth;

  @override
  Widget build(BuildContext context) {
    final bool desktop = usesDesktopPointerUi(context);
    final EdgeInsets insets = desktop
        ? wideSettingsDesktopModalInsets(context)
        : wideSettingsModalInsets(context, maxModalWidth: maxModalWidth);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          StarGestureDetector(
            onTap: () => context.pop(),
            behavior: HitTestBehavior.opaque,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Padding(
            padding: insets,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: desktop
                      ? wideSettingsDesktopModalMaxWidth(context)
                      : maxModalWidth,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
