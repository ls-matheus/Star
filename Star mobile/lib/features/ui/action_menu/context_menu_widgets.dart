import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

const double kContextMenuWidth = kStarDesktopMenuMinWidth;
const kContextMenuTitleHeight = 40.0;
const kContextMenuEntranceDuration = Duration(milliseconds: 120);

class ContextMenuEntranceAnimation extends StatelessWidget {
  const ContextMenuEntranceAnimation({
    required this.animation,
    required this.child,
    this.alignment = Alignment.center,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        alignment: alignment,
        child: child,
      ),
    );
  }
}

class ContextMenuEntranceAnimationHost extends StatefulWidget {
  const ContextMenuEntranceAnimationHost({
    required this.child,
    this.alignment = Alignment.center,
    super.key,
  });

  final Widget child;
  final Alignment alignment;

  @override
  State<ContextMenuEntranceAnimationHost> createState() =>
      _ContextMenuEntranceAnimationHostState();
}

class _ContextMenuEntranceAnimationHostState
    extends State<ContextMenuEntranceAnimationHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kContextMenuEntranceDuration,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContextMenuEntranceAnimation(
      animation: _controller,
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}

class ContextMenuTitle extends StatelessWidget {
  const ContextMenuTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    return SizedBox(
      height: kContextMenuTitleHeight,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: layout.s1),
          child: Text(
            title,
            style: context.textStyles.label.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class ContextMenuPanel extends StatelessWidget {
  final List<Widget> items;

  const ContextMenuPanel({required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return StarDesktopMenuPanel(
      width: kContextMenuWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );
  }
}

class ContextMenuItem extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isDanger;
  final bool isDisabled;
  final VoidCallback onTap;

  const ContextMenuItem({
    required this.label,
    required this.onTap,
    this.hint,
    this.icon,
    this.isDanger = false,
    this.isDisabled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StarDesktopMenuRow(
      label: label,
      hint: hint,
      onTap: onTap,
      isDanger: isDanger,
      enabled: !isDisabled,
      trailing: icon == null
          ? null
          : PhosphorIcon(
              icon!,
              size: kStarDesktopMenuIconSize,
              color: isDisabled
                  ? context.colors.interactiveMuted
                  : isDanger
                  ? starDesktopMenuDangerText(context.colors)
                  : context.colors.textPrimary,
            ),
    );
  }
}

class ContextMenuDivider extends StatelessWidget {
  const ContextMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const StarDesktopMenuSeparator();
  }
}

@StarWidgetPreview(name: 'Panel', group: 'ContextMenu')
Widget contextMenuPanelPreview() {
  return ContextMenuPanel(
    items: [
      ContextMenuItem(
        label: 'Reply',
        icon: PhosphorIconsBold.arrowBendUpLeft,
        onTap: () {},
      ),
      const ContextMenuDivider(),
      ContextMenuItem(
        label: 'Delete',
        hint: 'Remove for everyone',
        icon: PhosphorIconsBold.trash,
        isDanger: true,
        onTap: () {},
      ),
    ],
  );
}

Offset contextMenuPositionAtCenter(BuildContext context) {
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  if (box == null) {
    return Offset.zero;
  }
  final Offset origin = box.localToGlobal(Offset.zero);
  return origin + Offset(box.size.width / 2, box.size.height / 2);
}

Offset contextMenuPositionAtPointer(
  BuildContext context, {
  double horizontalFactor = 0.75,
}) {
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  if (box == null) {
    return Offset.zero;
  }
  final Offset origin = box.localToGlobal(Offset.zero);
  return origin +
      Offset(box.size.width * horizontalFactor, box.size.height / 2);
}

double estimateContextMenuHeight(List<Widget> items) {
  var height = kStarDesktopMenuPadding * 2 + 2;
  for (final item in items) {
    if (item is ContextMenuDivider) {
      height += 9;
    } else if (item is ContextMenuTitle) {
      height += kContextMenuTitleHeight;
    } else {
      height += kStarDesktopMenuRowMinHeight;
    }
  }
  return height;
}
