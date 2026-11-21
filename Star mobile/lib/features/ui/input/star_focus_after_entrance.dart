import 'package:star_app/material_ui.dart';

class StarFocusAfterEntrance extends StatefulWidget {
  const StarFocusAfterEntrance({
    required this.focusNode,
    required this.child,
    super.key,
  });

  final FocusNode focusNode;
  final Widget child;

  @override
  State<StarFocusAfterEntrance> createState() =>
      _StarFocusAfterEntranceState();
}

class _StarFocusAfterEntranceState extends State<StarFocusAfterEntrance> {
  Animation<double>? _animation;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Animation<double>? animation = ModalRoute.of(context)?.animation;
    if (identical(animation, _animation)) {
      return;
    }
    _animation?.removeStatusListener(_handleStatus);
    _animation = animation;
    if (animation == null || animation.isCompleted) {
      _requestFocus();
      return;
    }
    animation.addStatusListener(_handleStatus);
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_handleStatus);
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _animation?.removeStatusListener(_handleStatus);
      _requestFocus();
    }
  }

  void _requestFocus() {
    if (_requested) {
      return;
    }
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
