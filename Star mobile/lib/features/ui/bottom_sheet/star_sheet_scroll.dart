import 'dart:math' as math;

import 'package:flutter/gestures.dart' show Drag;
import 'package:flutter/physics.dart' show Tolerance, nearEqual;
import 'package:flutter/rendering.dart'
    show RenderSliver, RenderViewportBase, SliverGeometry;
import 'package:star_app/material_ui.dart';

typedef StarSheetContentExtentCallback =
    void Function(double viewportExtent, double contentExtent);

abstract interface class StarSheetDragTarget {
  bool get canExpand;

  void dragBy(double deltaDy);

  void endDrag(double velocityDy);
}

class StarSheetScrollController extends ScrollController {
  StarSheetScrollController(
    this.target, {
    this.dragsWhenShort = false,
    this.drivesSheet = true,
    this.onContentExtent,
  });

  final StarSheetDragTarget target;
  final bool dragsWhenShort;
  final bool drivesSheet;
  final StarSheetContentExtentCallback? onContentExtent;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _StarSheetScrollPosition(
      physics: _StarSheetContentPhysics(
        dragsWhenShort: dragsWhenShort,
        parent: physics,
      ),
      context: context,
      oldPosition: oldPosition,
      target: target,
      drivesSheet: drivesSheet,
      onContentExtent: onContentExtent,
    );
  }
}

class _StarSheetContentPhysics extends ScrollPhysics {
  const _StarSheetContentPhysics({
    required this.dragsWhenShort,
    super.parent,
  });

  final bool dragsWhenShort;

  @override
  _StarSheetContentPhysics applyTo(ScrollPhysics? ancestor) {
    return _StarSheetContentPhysics(
      dragsWhenShort: dragsWhenShort,
      parent: buildParent(ancestor),
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return dragsWhenShort ||
        position.maxScrollExtent > position.minScrollExtent ||
        position.pixels != position.minScrollExtent;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final double min = position.minScrollExtent;
    if (value < min && value < position.pixels) {
      return value - math.min(min, position.pixels);
    }
    return super.applyBoundaryConditions(position, value);
  }
}

enum _StarSheetDragOwner { none, content, sheet }

class _StarSheetScrollPosition extends ScrollPositionWithSingleContext {
  _StarSheetScrollPosition({
    required super.physics,
    required super.context,
    required this.target,
    required this.drivesSheet,
    required this.onContentExtent,
    super.oldPosition,
  });

  final StarSheetDragTarget target;
  final bool drivesSheet;
  final StarSheetContentExtentCallback? onContentExtent;
  _StarSheetDragOwner _owner = _StarSheetDragOwner.none;

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    final StarSheetContentExtentCallback? report = onContentExtent;
    if (report != null && hasViewportDimension && axis == Axis.vertical) {
      final double? content = _sliverExtent();
      if (content != null) {
        report(viewportDimension, content);
      }
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  double? _sliverExtent() {
    RenderViewportBase? viewport;
    void find(RenderObject child) {
      if (viewport != null) {
        return;
      }
      if (child is RenderViewportBase) {
        viewport = child;
        return;
      }
      child.visitChildren(find);
    }

    context.notificationContext?.findRenderObject()?.visitChildren(find);
    final RenderViewportBase? found = viewport;
    if (found == null) {
      return null;
    }
    double extent = 0;
    RenderSliver? sliver = found.firstChild;
    while (sliver != null) {
      final SliverGeometry? geometry = sliver.geometry;
      if (geometry == null) {
        return null;
      }
      extent += geometry.scrollExtent;
      sliver = found.childAfter(sliver);
    }
    return extent;
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    _owner = _StarSheetDragOwner.none;
    return super.drag(details, dragCancelCallback);
  }

  @override
  void applyUserOffset(double delta) {
    if (!drivesSheet) {
      super.applyUserOffset(delta);
      return;
    }
    if (_owner == _StarSheetDragOwner.none) {
      final bool atTop = pixels <= minScrollExtent;
      _owner = atTop && (delta > 0 || target.canExpand)
          ? _StarSheetDragOwner.sheet
          : _StarSheetDragOwner.content;
    }
    if (_owner == _StarSheetDragOwner.sheet) {
      target.dragBy(delta);
      return;
    }
    if (delta > 0) {
      final double room = pixels - minScrollExtent;
      if (delta > room) {
        if (room > 0) {
          super.applyUserOffset(room);
        }
        _owner = _StarSheetDragOwner.sheet;
        target.dragBy(delta - room);
        return;
      }
    } else if (maxScrollExtent <= minScrollExtent &&
        pixels <= minScrollExtent) {
      return;
    }
    super.applyUserOffset(delta);
  }

  @override
  void correctBy(double correction) {
    if (hasContentDimensions &&
        _clampsTrailingOverscroll(pixels + correction)) {
      return;
    }
    super.correctBy(correction);
  }

  bool _clampsTrailingOverscroll(double corrected) {
    return pixels > maxScrollExtent &&
        nearEqual(
          corrected,
          maxScrollExtent,
          Tolerance.defaultTolerance.distance,
        );
  }

  @override
  void goBallistic(double velocity) {
    final _StarSheetDragOwner owner = _owner;
    _owner = _StarSheetDragOwner.none;
    if (owner == _StarSheetDragOwner.sheet) {
      target.endDrag(-velocity);
      super.goBallistic(0);
      return;
    }
    super.goBallistic(velocity);
  }
}
