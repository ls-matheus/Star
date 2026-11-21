import 'dart:async';

import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

enum StarPopoutPosition { above, below, left, right }

typedef StarPopoutAnchorBuilder =
    Widget Function(BuildContext context, VoidCallback toggle);

typedef StarPopoutContentBuilder =
    Widget Function(BuildContext context, VoidCallback close);

class StarPopout extends StatefulWidget {
  const StarPopout({
    required this.anchorBuilder,
    required this.contentBuilder,
    this.position = StarPopoutPosition.below,
    this.gap = 4,
    this.fadeOnDesktop = true,
    this.backgroundColor,
    super.key,
  });

  final StarPopoutAnchorBuilder anchorBuilder;
  final StarPopoutContentBuilder contentBuilder;
  final StarPopoutPosition position;
  final double gap;
  final bool fadeOnDesktop;
  final Color? backgroundColor;

  @override
  State<StarPopout> createState() => _StarPopoutState();
}

class _StarPopoutState extends State<StarPopout>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  static const Duration _fadeDuration = StarMotionTheme.normalDuration;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _fadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationController.duration = context.motion.normal;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_overlayController.isShowing) {
      _close();
    } else {
      _overlayController.show();
      if (_skipsFade) {
        _animationController.value = 1;
      } else {
        _animationController.forward();
      }
    }
  }

  bool get _skipsFade => !widget.fadeOnDesktop && usesDesktopPointerUi(context);

  void _close() {
    if (_skipsFade) {
      _animationController.value = 0;
      if (_overlayController.isShowing) {
        _overlayController.hide();
      }
      return;
    }
    unawaited(
      _animationController.reverse().then((_) {
        if (mounted && _overlayController.isShowing) {
          _overlayController.hide();
        }
      }),
    );
  }

  Alignment _getTargetAnchor() {
    return switch (widget.position) {
      StarPopoutPosition.above => Alignment.topCenter,
      StarPopoutPosition.below => Alignment.bottomCenter,
      StarPopoutPosition.left => Alignment.centerLeft,
      StarPopoutPosition.right => Alignment.centerRight,
    };
  }

  Alignment _getFollowerAnchor() {
    return switch (widget.position) {
      StarPopoutPosition.above => Alignment.bottomCenter,
      StarPopoutPosition.below => Alignment.topCenter,
      StarPopoutPosition.left => Alignment.centerRight,
      StarPopoutPosition.right => Alignment.centerLeft,
    };
  }

  Offset _getOffset() {
    final double gap = widget.gap;
    return switch (widget.position) {
      StarPopoutPosition.above => Offset(0, -gap),
      StarPopoutPosition.below => Offset(0, gap),
      StarPopoutPosition.left => Offset(-gap, 0),
      StarPopoutPosition.right => Offset(gap, 0),
    };
  }

  Widget _buildOverlay(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return Stack(
      children: [
        Positioned.fill(
          child: StarGestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        FadeTransition(
          opacity: _fadeAnimation,
          child: CompositedTransformFollower(
            link: _layerLink,
            targetAnchor: _getTargetAnchor(),
            followerAnchor: _getFollowerAnchor(),
            offset: _getOffset(),
            child: Align(
              alignment: _getFollowerAnchor(),
              child: IntrinsicWidth(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? colors.backgroundFloating,
                    borderRadius: layout.radiusLg,
                    border: Border.all(color: colors.backgroundModifierAccent),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.contentBuilder(context, _close),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: _buildOverlay,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: widget.anchorBuilder(context, _toggle),
      ),
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarPopout')
Widget starPopoutPreview() {
  return StarPopout(
    anchorBuilder: (context, toggle) {
      return TextButton(onPressed: toggle, child: const Text('Open popout'));
    },
    contentBuilder: (context, close) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Popout panel'),
            TextButton(onPressed: close, child: const Text('Close')),
          ],
        ),
      );
    },
  );
}
