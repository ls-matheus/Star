import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';

class RetargetingScalar extends StatefulWidget {
  const RetargetingScalar({
    required this.target,
    required this.builder,
    super.key,
  });

  final double target;
  final Widget Function(BuildContext context, double value) builder;

  @override
  State<RetargetingScalar> createState() => _RetargetingScalarState();
}

class _RetargetingScalarState extends State<RetargetingScalar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation = const AlwaysStoppedAnimation<double>(0);

  @override
  void initState() {
    super.initState();
    _animation = AlwaysStoppedAnimation<double>(widget.target);
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(RetargetingScalar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target == widget.target) {
      return;
    }
    final double begin = _animation.value;
    final StarMotionTheme motion = context.motion;
    if (motion.panel <= Duration.zero) {
      _animation = AlwaysStoppedAnimation<double>(widget.target);
      return;
    }
    _controller
      ..stop()
      ..duration = motion.panel;
    _animation = Tween<double>(begin: begin, end: widget.target).animate(
      CurvedAnimation(parent: _controller, curve: motion.emphasizedCurve),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return widget.builder(context, _animation.value);
      },
    );
  }
}
