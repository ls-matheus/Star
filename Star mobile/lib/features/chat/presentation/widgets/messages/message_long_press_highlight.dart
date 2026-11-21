import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/material_ui.dart';

class MessageLongPressHighlight extends StatelessWidget {
  const MessageLongPressHighlight({required this.active, super.key});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: context.motion.fast,
        curve: context.motion.curve,
        child: ColoredBox(color: context.colors.backgroundModifierHover),
      ),
    );
  }
}
