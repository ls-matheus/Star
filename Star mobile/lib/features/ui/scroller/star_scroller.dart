import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/scroller/star_smooth_scrollbar.dart';
import 'package:star_app/material_ui.dart';

class StarScroller extends StatefulWidget {
  const StarScroller({required this.child, this.controller, super.key});

  final Widget child;
  final ScrollController? controller;

  @override
  State<StarScroller> createState() => _StarScrollerState();
}

class _StarScrollerState extends State<StarScroller> {
  ScrollController? _internalController;

  ScrollController get _effectiveController =>
      widget.controller ?? (_internalController ??= ScrollController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _effectiveController,
      child: StarSmoothScrollbar(
        controller: _effectiveController,
        child: widget.child,
      ),
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarScroller')
Widget starScrollerPreview() {
  return SizedBox(
    height: 160,
    width: 220,
    child: StarScroller(
      child: ListView(
        children: List.generate(
          12,
          (int i) => ListTile(title: Text('Row ${i + 1}')),
        ),
      ),
    ),
  );
}
