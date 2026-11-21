import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_color_mix.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/foldable/crease_overlay_layout.dart';
import 'package:star_app/features/shell/foldable/device_fold_posture.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

export 'package:star_app/core/theme/star_color_mix.dart';

part 'star_desktop_elevation.dart';
part 'star_desktop_menu.dart';
part 'star_desktop_route.dart';
part 'star_desktop_hover_flyout.dart';

const double kStarDesktopMenuMinWidth = 208;
const double kStarDesktopMenuMaxWidth = 344;
const double kStarDesktopMenuDefaultWidth = 240;
const double kStarDesktopMenuHintMaxWidth = 320;
const double kStarDesktopMenuPointerOffset = 4;
const double kStarDesktopMenuPadding = 6;
const double kStarDesktopMenuRowMinHeight = 32;
const double kStarDesktopMenuIconSize = 18;
const double kStarDesktopMenuCaretSize = 14;
const double kStarDesktopSurfaceEdgePadding = 12;
const double _kEdgePadding = kStarDesktopSurfaceEdgePadding;
const double _kAnchorGap = 4;
const double _kPopoutSideGap = 8;
const double _kAnchorMaxWidth = 420;
const double _kAnchorMaxHeight = 160;
const Duration _kFlyoutCloseDelay = Duration(milliseconds: 120);

enum StarDesktopSurface { menu, popout, modal }

enum StarDesktopPlacement {
  belowStart,
  belowEnd,
  aboveStart,
  rightStart,
  leftStart,
}

class StarDesktopPresentation {
  const StarDesktopPresentation({
    this.surface,
    this.width,
    this.placement = StarDesktopPlacement.belowStart,
    this.anchorContext,
    this.showPanelBorder = true,
    this.borderRadius,
  });

  final StarDesktopSurface? surface;
  final double? width;
  final StarDesktopPlacement placement;
  final BuildContext? anchorContext;
  final bool showPanelBorder;
  final double? borderRadius;
}

class StarDesktopSurfaceScope extends InheritedWidget {
  const StarDesktopSurfaceScope({
    required this.surface,
    required super.child,
    super.key,
  });

  final StarDesktopSurface surface;

  static StarDesktopSurface? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<StarDesktopSurfaceScope>()
      ?.surface;

  static bool isMenu(BuildContext context) =>
      maybeOf(context) == StarDesktopSurface.menu;

  @override
  bool updateShouldNotify(StarDesktopSurfaceScope oldWidget) =>
      surface != oldWidget.surface;
}
