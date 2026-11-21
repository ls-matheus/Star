import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/obscuring_overlay_tracker_provider.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/foldable/crease_overlay_layout.dart';
import 'package:star_app/features/shell/foldable/device_fold_posture.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/utils/shell_popup_presentation.dart';
import 'package:star_app/features/ui/action_menu/sidebar_peek_menu_constants.dart';
import 'package:star_app/features/ui/badge/star_settings_status_badge.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet_drag.dart';
import 'package:star_app/features/ui/bottom_sheet/star_sheet_motion.dart';
import 'package:star_app/features/ui/bottom_sheet/star_sheet_scroll.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/overlay/star_overlay_back_handler.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/radio_group/star_radio_group.dart';
import 'package:star_app/features/ui/selected_check/star_selected_check.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

part 'star_bottom_sheet_desktop.dart';

typedef StarBottomSheetBuilder =
    Widget Function(BuildContext context, VoidCallback close);

typedef StarScrollableBottomSheetBuilder =
    Widget Function(
      BuildContext context,
      ScrollController scrollController,
      VoidCallback close,
    );

enum StarBottomSheetVariant { content, menu }

class StarBottomSheetScope extends InheritedWidget {
  const StarBottomSheetScope({
    required this.bottomScrollPadding,
    required super.child,
    super.key,
  });

  final double bottomScrollPadding;

  static StarBottomSheetScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StarBottomSheetScope>();
  }

  @override
  bool updateShouldNotify(StarBottomSheetScope oldWidget) {
    return bottomScrollPadding != oldWidget.bottomScrollPadding;
  }
}

AnimationStyle starBottomSheetAnimationStyle(
  BuildContext context, {
  bool leadBackdrop = false,
}) {
  final StarMotionTheme motion = context.motion;
  final bool animated = motion.sheet > Duration.zero;
  final Duration lead = leadBackdrop && animated
      ? kStarSheetBackdropLead
      : Duration.zero;
  final Duration duration = motion.sheet + lead;
  return AnimationStyle(
    duration: duration,
    curve: lead > Duration.zero
        ? Interval(
            lead.inMicroseconds / duration.inMicroseconds,
            1,
            curve: motion.sheetCurve,
          )
        : motion.sheetCurve,
    reverseDuration: animated ? kStarSheetCloseDuration : Duration.zero,
    reverseCurve: Curves.linear,
  );
}

bool _resolveSheetRootNavigator(BuildContext context, bool? useRootNavigator) {
  return useRootNavigator ?? resolveShellPopupUseRootNavigator(context);
}

Future<T?> _pushStarSheetRoute<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required bool useRootNavigator,
  required bool isDismissible,
  required bool useSafeArea,
  required AnimationStyle animationStyle,
  Color? barrierColor,
}) {
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  final MaterialLocalizations localizations = MaterialLocalizations.of(context);
  final Route<dynamic>? origin = ModalRoute.of(context);
  final StarSheetRoute<dynamic>? last = _lastSheetByNavigator[navigator];
  if (last != null &&
      origin != null &&
      identical(last.origin, origin) &&
      last.isCurrent &&
      last.isEntering) {
    return Future<T?>.value();
  }
  final Duration lead = animationStyle.duration! - context.motion.sheet;
  final StarSheetRoute<T> route = StarSheetRoute<T>(
    builder: builder,
    origin: origin,
    inputLockout: animationStyle.duration! > Duration.zero
        ? lead + kStarSheetInputLockout
        : Duration.zero,
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    isScrollControlled: true,
    barrierLabel: localizations.modalBarrierDismissLabel,
    barrierOnTapHint: localizations.scrimOnTapHint(
      localizations.bottomSheetLabel,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    isDismissible: isDismissible,
    modalBarrierColor: barrierColor ?? kStarSheetScrimColor,
    enableDrag: false,
    useSafeArea: useSafeArea,
    sheetAnimationStyle: animationStyle,
  );
  _lastSheetByNavigator[navigator] = route;
  return navigator.push(route);
}

final Expando<StarSheetRoute<dynamic>> _lastSheetByNavigator =
    Expando<StarSheetRoute<dynamic>>();

final Expando<StarDesktopRoute<dynamic>> _lastDesktopByNavigator =
    Expando<StarDesktopRoute<dynamic>>();

void closeStarSheetOpenedFrom(
  BuildContext context, {
  bool? useRootNavigator,
}) {
  final NavigatorState? navigator = Navigator.maybeOf(
    context,
    rootNavigator: _resolveSheetRootNavigator(context, useRootNavigator),
  );
  if (navigator == null) {
    return;
  }
  final Route<dynamic>? origin = ModalRoute.of(context);
  final StarDesktopRoute<dynamic>? desktop =
      _lastDesktopByNavigator[navigator];
  if (desktop != null &&
      desktop.isActive &&
      identical(desktop.origin, origin)) {
    navigator.removeRoute(desktop);
    return;
  }
  final StarSheetRoute<dynamic>? last = _lastSheetByNavigator[navigator];
  if (last == null || !identical(last.origin, origin)) {
    return;
  }
  last.closeSelf();
}

Future<void> handOffStarSheet(BuildContext context) {
  final NavigatorState? navigator = Navigator.maybeOf(context);
  final StarSheetRoute<dynamic>? closing = navigator == null
      ? null
      : _lastSheetByNavigator[navigator];
  closing?.holdScrimForHandoff();
  final Animation<double>? exit = closing?.animation;
  bool settled() =>
      exit!.status != AnimationStatus.reverse ||
      exit.value <= kStarSheetHandoffRemaining;
  if (exit == null || settled()) {
    return Future<void>.value();
  }
  final Completer<void> done = Completer<void>();
  void check() {
    if (settled()) {
      exit.removeListener(check);
      done.complete();
    }
  }

  exit.addListener(check);
  return done.future;
}

void _closeSheet(BuildContext sheetContext) {
  final ModalRoute<dynamic>? route = sheetContext.mounted
      ? ModalRoute.of(sheetContext)
      : null;
  if (route is StarSheetRoute) {
    route.closeSelf();
    return;
  }
  if (route != null && route.isActive) {
    Navigator.of(sheetContext).pop();
  }
}

class StarBottomSheet {
  StarBottomSheet._();

  static const double scrollableSheetSize = kStarBottomSheetFullSize;
  static const double scrollableSheetHalfSize = kStarBottomSheetHalfSize;

  static double scrollBottomPaddingOf(BuildContext context) {
    return StarBottomSheetScope.maybeOf(context)?.bottomScrollPadding ?? 0;
  }

  static EdgeInsets scrollViewPadding(
    BuildContext context, {
    EdgeInsetsGeometry? padding,
  }) {
    if (StarDesktopSurfaceScope.isMenu(context)) {
      return EdgeInsets.zero;
    }
    final EdgeInsets resolved =
        padding?.resolve(Directionality.of(context)) ?? EdgeInsets.zero;
    final double bottom = scrollBottomPaddingOf(context);
    if (bottom <= 0) {
      return resolved;
    }
    return resolved.copyWith(bottom: resolved.bottom + bottom);
  }

  static bool isInSheet(BuildContext context) {
    return _StarSheetSurfaceScope.contains(context);
  }

  static double systemBottomInsetOf(BuildContext context) {
    return _starSystemBottomInset(MediaQuery.of(context));
  }

  static Color cardColorOf(BuildContext context) {
    final StarColorTheme colors = context.colors;
    return _StarSheetSurfaceScope.contains(context)
        ? colors.backgroundTertiary
        : colors.backgroundSecondaryAlt;
  }

  static double systemEndInsetOf(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    if (isRtl) {
      return math.max(
        mediaQuery.viewPadding.left,
        math.max(mediaQuery.padding.left, mediaQuery.systemGestureInsets.left),
      );
    }
    return math.max(
      mediaQuery.viewPadding.right,
      math.max(mediaQuery.padding.right, mediaQuery.systemGestureInsets.right),
    );
  }

  static Future<T?> _showWithOverlayTracking<T>(
    BuildContext context,
    Future<T?> Function() showSheet,
  ) {
    final ProviderContainer container = ProviderScope.containerOf(context);
    container.read(obscuringOverlayTrackerProvider.notifier).push();
    return showSheet().whenComplete(() {
      container.read(obscuringOverlayTrackerProvider.notifier).pop();
    });
  }

  static Future<T?> show<T>(
    BuildContext context, {
    required StarBottomSheetBuilder builder,
    String? title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onBack,
    bool showDragHandle = true,
    bool? useRootNavigator,
    StarBottomSheetVariant variant = StarBottomSheetVariant.content,
    ValueNotifier<bool>? canDismissNotifier,
    bool enableDrag = true,
    double? maxHeight,
    bool isDismissible = true,
    bool reserveBottomInset = true,
    bool manageKeyboardInset = true,
    bool bottomGap = true,
    Color? barrierColor,
    StarDesktopPresentation desktop = const StarDesktopPresentation(),
  }) {
    final layout = context.layout;
    final bool rootNavigator = _resolveSheetRootNavigator(
      context,
      useRootNavigator,
    );

    if (usesDesktopPointerUi(context)) {
      return _showWithOverlayTracking<T>(
        context,
        () => _showStarDesktopSheet<T>(
          context,
          surface:
              desktop.surface ??
              (variant == StarBottomSheetVariant.menu
                  ? StarDesktopSurface.menu
                  : StarDesktopSurface.modal),
          presentation: desktop,
          useRootNavigator: rootNavigator,
          isDismissible: isDismissible,
          barrierColor: barrierColor,
          canDismissNotifier: canDismissNotifier,
          onBack: onBack,
          maxHeight: maxHeight,
          buildHeader: (BuildContext headerContext) => _buildDesktopHeader(
            headerContext,
            title: title,
            subtitle: subtitle,
            leading: leading,
            trailing: trailing,
            onBack: onBack,
            isDismissible: isDismissible,
          ),
          buildBody: (BuildContext sheetContext) => Flexible(
            child: Builder(
              builder: (BuildContext scopedContext) =>
                  builder(scopedContext, () => _closeSheet(sheetContext)),
            ),
          ),
        ),
      );
    }

    return _showWithOverlayTracking<T>(
      context,
      () => _pushStarSheetRoute<T>(
        context,
        useRootNavigator: rootNavigator,
        isDismissible: isDismissible,
        barrierColor: barrierColor,
        animationStyle: starBottomSheetAnimationStyle(context),
        useSafeArea: reserveBottomInset,
        builder: (sheetContext) {
          void close() => _closeSheet(sheetContext);

          final bool isMenuVariant = variant == StarBottomSheetVariant.menu;
          final bool hasHeader = _hasSheetHeader(
            title: title,
            subtitle: subtitle,
            leading: leading,
            trailing: trailing,
            onBack: onBack,
          );

          final Widget content = _StarSheetKeyboardInset(
            enabled: manageKeyboardInset,
            builder: (BuildContext insetContext, double keyboardInset) {
              final mediaQuery = MediaQuery.of(insetContext);
              final double maxContentHeight =
                  mediaQuery.size.height -
                  mediaQuery.viewPadding.top -
                  layout.s4;
              final bottomPadding = _effectiveBottomSheetBottomPadding(
                insetContext,
                reserveBottomInset,
                keyboardBottomInset: keyboardInset,
                bottomGap: bottomGap,
              );
              return Padding(
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight != null
                        ? maxContentHeight * maxHeight
                        : maxContentHeight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showDragHandle) const StarBottomSheetDragHandle(),
                      if (!showDragHandle && hasHeader)
                        SizedBox(height: layout.s4),
                      if (hasHeader)
                        _StarBottomSheetHeaderBlock(
                          title: title ?? '',
                          subtitle: subtitle,
                          leading: leading,
                          trailing: trailing,
                          onBack: onBack,
                          gap: isMenuVariant ? layout.s3 : layout.s2,
                        ),
                      Flexible(
                        child: StarBottomSheetDragArea(
                          behavior: HitTestBehavior.translucent,
                          child: _StarBottomSheetInsetChild(
                            bottomPadding: bottomPadding,
                            child: isMenuVariant
                                ? Builder(
                                    builder: (scopedContext) =>
                                        builder(scopedContext, close),
                                  )
                                : builder(sheetContext, close),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          final sheetContent = _StarSheetPresentation(
            navigator: Navigator.of(sheetContext, rootNavigator: rootNavigator),
            enableDrag: enableDrag,
            onDismiss: close,
            child: _wrapBottomSheetSurface(
              context: sheetContext,
              child: content,
            ),
          );

          return _buildSheetWithBackHandler(
            child: sheetContent,
            onBack: onBack,
            canDismissNotifier: canDismissNotifier,
          );
        },
      ),
    );
  }

  static Future<T?> showScrollable<T>(
    BuildContext context, {
    required StarScrollableBottomSheetBuilder builder,
    String? title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onBack,
    bool showDragHandle = true,
    bool? useRootNavigator,
    double initialChildSize = scrollableSheetSize,
    double minChildSize = 0.4,
    double maxChildSize = scrollableSheetSize,
    ValueNotifier<bool>? canDismissNotifier,
    double? maxHeight,
    bool isDismissible = true,
    bool reserveBottomInset = true,
    bool manageKeyboardInset = true,
    bool bottomGap = true,
    double? sheetHeight,
    AnimationStyle? animationStyle,
    Color? barrierColor,
    StarDesktopPresentation desktop = const StarDesktopPresentation(),
  }) {
    if (usesDesktopPointerUi(context)) {
      final bool rootNavigator = _resolveSheetRootNavigator(
        context,
        useRootNavigator,
      );
      return _showWithOverlayTracking<T>(
        context,
        () => _showStarDesktopSheet<T>(
          context,
          surface: desktop.surface ?? StarDesktopSurface.modal,
          presentation: desktop,
          defaultModalWidth: _kDesktopModalMediumWidth,
          useRootNavigator: rootNavigator,
          isDismissible: isDismissible,
          barrierColor: barrierColor,
          canDismissNotifier: canDismissNotifier,
          onBack: onBack,
          buildHeader: (_) => null,
          buildBody: (BuildContext sheetContext) =>
              _StarDesktopScrollableBody(
                maxHeight: sheetHeight,
                heightFactor: maxHeight,
                header: (BuildContext headerContext) => _buildDesktopHeader(
                  headerContext,
                  title: title,
                  subtitle: subtitle,
                  leading: leading,
                  trailing: trailing,
                  onBack: onBack,
                  isDismissible: isDismissible,
                ),
                builder:
                    (BuildContext scopedContext, ScrollController scroll) =>
                        builder(
                          scopedContext,
                          scroll,
                          () => _closeSheet(sheetContext),
                        ),
              ),
        ),
      );
    }

    final layout = context.layout;
    final bool cardBackdrop = sheetHeight == null;
    final double effectiveMaxChildSize = sheetHeight != null
        ? 1
        : maxHeight ?? maxChildSize;
    final double effectiveInitialChildSize = sheetHeight != null
        ? 1
        : math.min(initialChildSize, effectiveMaxChildSize);
    final bool parallax =
        cardBackdrop &&
        _starSheetOpensFullHeight(
          initialChildSize: effectiveInitialChildSize,
          maxChildSize: effectiveMaxChildSize,
        );
    final bool rootNavigator = _resolveSheetRootNavigator(
      context,
      useRootNavigator,
    );

    return _showWithOverlayTracking<T>(
      context,
      () => _pushStarSheetRoute<T>(
        context,
        useRootNavigator: rootNavigator,
        isDismissible: isDismissible,
        barrierColor: barrierColor,
        animationStyle:
            animationStyle ??
            starBottomSheetAnimationStyle(
              context,
              leadBackdrop: parallax && _starSheetDrivesBackdrop(context),
            ),
        useSafeArea: reserveBottomInset,
        builder: (sheetContext) {
          void close() => _closeSheet(sheetContext);

          final bool hasHeader = _hasSheetHeader(
            title: title,
            subtitle: subtitle,
            leading: leading,
            trailing: trailing,
            onBack: onBack,
          );

          final Widget sheet = _StarSheetKeyboardInset(
            enabled: manageKeyboardInset,
            builder: (BuildContext insetContext, double keyboardInset) {
              final mediaQuery = MediaQuery.of(insetContext);
              final double availableHeight =
                  sheetHeight ??
                  mediaQuery.size.height -
                      mediaQuery.viewPadding.top -
                      layout.s4;
              final double halfChildSize = cardBackdrop
                  ? scrollableSheetHalfSize.clamp(0, effectiveMaxChildSize)
                  : effectiveMaxChildSize;
              return StarDraggableScrollableSheet(
                minChildSize: math.min(
                  kStarBottomSheetDragMinSize,
                  math.min(minChildSize, effectiveMaxChildSize),
                ),
                maxChildSize: effectiveMaxChildSize,
                halfChildSize: halfChildSize,
                initialChildSize: effectiveInitialChildSize,
                maxHeight: availableHeight,
                fitContent: cardBackdrop,
                showDragHandle: showDragHandle,
                hasHeader: hasHeader,
                onDismiss: close,
                navigator: Navigator.of(
                  sheetContext,
                  rootNavigator: rootNavigator,
                ),
                title: title,
                subtitle: subtitle,
                leading: leading,
                trailing: trailing,
                onBack: onBack,
                bottomInset: keyboardInset,
                bottomScrollPadding: _effectiveBottomSheetBottomPadding(
                  insetContext,
                  reserveBottomInset,
                  keyboardBottomInset: keyboardInset,
                  bottomGap: bottomGap,
                ),
                sheetContext: sheetContext,
                builder: builder,
              );
            },
          );

          return _buildSheetWithBackHandler(
            child: sheet,
            onBack: onBack,
            canDismissNotifier: canDismissNotifier,
          );
        },
      ),
    );
  }
}

bool _starSheetOpensFullHeight({
  required double initialChildSize,
  required double maxChildSize,
}) {
  return initialChildSize >= maxChildSize - _kSheetSizeEpsilon &&
      maxChildSize >= kStarBottomSheetFullSize - _kSheetSizeEpsilon;
}

Widget _buildSheetWithBackHandler({
  required Widget child,
  required VoidCallback? onBack,
  required ValueNotifier<bool>? canDismissNotifier,
}) {
  if (canDismissNotifier == null) {
    return _wrapSheetBackHandler(
      canDismiss: true,
      onBack: onBack,
      child: child,
    );
  }
  return ValueListenableBuilder<bool>(
    valueListenable: canDismissNotifier,
    builder: (BuildContext context, bool canDismiss, Widget? sheetChild) =>
        _wrapSheetBackHandler(
          canDismiss: canDismiss,
          onBack: onBack,
          child: sheetChild!,
        ),
    child: child,
  );
}

Widget _wrapSheetBackHandler({
  required bool canDismiss,
  required VoidCallback? onBack,
  required Widget child,
}) {
  return wrapStarOverlayBackHandler(
    canDismiss: canDismiss,
    onBack: onBack,
    onDismiss: null,
    child: child,
  );
}

bool _hasSheetHeader({
  String? title,
  Widget? subtitle,
  Widget? leading,
  Widget? trailing,
  VoidCallback? onBack,
}) {
  return title != null ||
      subtitle != null ||
      leading != null ||
      trailing != null ||
      onBack != null;
}

double _starSystemBottomInset(MediaQueryData mediaQuery) {
  return math.max(
    mediaQuery.viewPadding.bottom,
    math.max(mediaQuery.padding.bottom, mediaQuery.systemGestureInsets.bottom),
  );
}

double _effectiveBottomSheetBottomPadding(
  BuildContext context,
  bool reserveBottomInset, {
  required double keyboardBottomInset,
  required bool bottomGap,
}) {
  final MediaQueryData mediaQuery = MediaQuery.of(context);
  final double systemInset = _starSystemBottomInset(mediaQuery);
  final double inset = reserveBottomInset
      ? math.max(0, systemInset - keyboardBottomInset)
      : 0;
  if (!bottomGap) {
    return inset;
  }
  final bool coversInset = systemInset > 0 && mediaQuery.viewInsets.bottom <= 0;
  return inset + (coversInset ? 0 : context.layout.s4);
}

Widget _wrapBottomSheetSurface({
  required BuildContext context,
  required Widget child,
}) {
  final BottomSheetThemeData bottomSheetTheme = Theme.of(
    context,
  ).bottomSheetTheme;
  final Color surfaceColor = context.colors.backgroundSecondaryAlt;
  return Stack(
    fit: StackFit.passthrough,
    clipBehavior: Clip.none,
    children: <Widget>[
      Positioned(
        left: 0,
        right: 0,
        bottom: -kStarSheetOvershootBleed,
        height: kStarSheetOvershootBleed,
        child: ColoredBox(color: surfaceColor),
      ),
      Material(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: bottomSheetTheme.shape,
        clipBehavior: bottomSheetTheme.clipBehavior ?? Clip.antiAlias,
        child: _StarSheetSurfaceScope(child: child),
      ),
    ],
  );
}

bool _starSheetDrivesBackdrop(BuildContext context) {
  return isMobileLayout(context) &&
      Theme.of(context).platform != TargetPlatform.android &&
      !MediaQuery.disableAnimationsOf(context);
}

class _StarSheetKeyboardInset extends StatefulWidget {
  const _StarSheetKeyboardInset({
    required this.enabled,
    required this.builder,
  });

  final bool enabled;
  final Widget Function(BuildContext context, double keyboardInset) builder;

  @override
  State<_StarSheetKeyboardInset> createState() =>
      _StarSheetKeyboardInsetState();
}

class _StarSheetKeyboardInsetState extends State<_StarSheetKeyboardInset> {
  Animation<double>? _routeAnimation;
  bool _closing = false;
  double _inset = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Animation<double>? animation = ModalRoute.of(context)?.animation;
    if (identical(animation, _routeAnimation)) {
      return;
    }
    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    _routeAnimation = animation?..addStatusListener(_handleRouteStatus);
    _closing = _isClosing(animation?.status);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    super.dispose();
  }

  static bool _isClosing(AnimationStatus? status) {
    return status == AnimationStatus.reverse;
  }

  void _handleRouteStatus(AnimationStatus status) {
    final bool closing = _isClosing(status);
    if (closing != _closing) {
      setState(() => _closing = closing);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_closing) {
      _inset = widget.enabled ? MediaQuery.viewInsetsOf(context).bottom : 0;
    }
    return widget.builder(context, _inset);
  }
}

class _StarSheetPresentation extends StatefulWidget {
  const _StarSheetPresentation({
    required this.navigator,
    required this.enableDrag,
    required this.onDismiss,
    required this.child,
  });

  final NavigatorState navigator;
  final bool enableDrag;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  State<_StarSheetPresentation> createState() =>
      _StarSheetPresentationState();
}

class _StarSheetPresentationState extends State<_StarSheetPresentation>
    with SingleTickerProviderStateMixin
    implements StarSheetDragTarget {
  final ValueNotifier<double> _dragOffset = ValueNotifier<double>(0);
  final ValueNotifier<double> _recede = ValueNotifier<double>(0);
  late final StarSheetScrollController _scrollController =
      StarSheetScrollController(this);
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: StarMotionTheme.sheetDuration,
  )..addListener(_applySettle);
  double _settleFrom = 0;
  Animation<double>? _routeAnimation;
  StarSheetBackdropLink? _backdrop;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _dragOffset.addListener(_reportBackdrop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_starSheetDrivesBackdrop(context)) {
      _backdrop ??= StarSheetBackdropLink(
        widget.navigator,
        route: ModalRoute.of(context),
        onCovered: _reportBackdrop,
      );
    } else {
      _backdrop?.dispose();
      _backdrop = null;
      _recede.value = 0;
    }
    _route = ModalRoute.of(context);
    final Animation<double>? animation = _route?.animation;
    if (identical(animation, _routeAnimation)) {
      return;
    }
    _routeAnimation?.removeListener(_reportBackdrop);
    _routeAnimation = animation;
    _routeAnimation?.addListener(_reportBackdrop);
  }

  double? get _sheetHeight {
    final RenderObject? box = context.findRenderObject();
    return box is RenderBox && box.hasSize ? box.size.height : null;
  }

  @override
  void dispose() {
    _routeAnimation?.removeListener(_reportBackdrop);
    _backdrop?.dispose();
    _settle.dispose();
    _scrollController.dispose();
    _dragOffset.dispose();
    _recede.dispose();
    super.dispose();
  }

  @override
  bool get canExpand => false;

  @override
  void dragBy(double deltaDy) {
    if (!widget.enableDrag) {
      return;
    }
    _settle.stop();
    if (deltaDy > 0 && MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _dragOffset.value = math.max(0, _dragOffset.value + deltaDy);
  }

  @override
  void endDrag(double velocityDy) {
    if (!widget.enableDrag) {
      return;
    }
    final double offset = _dragOffset.value;
    if (offset > 0 &&
        starBottomSheetShouldDismissAfterDrag(
          dragDistance: offset,
          velocity: velocityDy,
          sheetHeight: _sheetHeight ?? double.infinity,
        )) {
      widget.onDismiss();
      return;
    }
    _settleBack();
  }

  void _settleBack() {
    if (_dragOffset.value == 0) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _dragOffset.value = 0;
      return;
    }
    _settleFrom = _dragOffset.value;
    _settle.forward(from: 0);
  }

  void _applySettle() {
    _dragOffset.value =
        _settleFrom *
        (1 - StarMotionTheme.standardSheetCurve.transform(_settle.value));
  }

  void _reportBackdrop() {
    final ModalRoute<dynamic>? route = _route;
    final Animation<double>? animation = _routeAnimation;
    final double? height = _sheetHeight;
    if (route == null || animation == null || height == null || height <= 0) {
      return;
    }
    final double travel = (1 - _dragOffset.value / height).clamp(0, 1);
    if (route is StarSheetRoute) {
      route.setScrimTravel(travel);
    }
    final StarSheetBackdropLink? backdrop = _backdrop;
    if (backdrop == null) {
      return;
    }
    if (!backdrop.covers(height)) {
      _recede.value = 0;
      backdrop.report(0);
      return;
    }
    final double depth = backdrop.depth;
    _recede.value = depth;
    backdrop.report(
      starSheetBackdropProgress(animation, route.transitionDuration) *
          travel *
          (1 + depth),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _StarSheetDragTargetScope(
      target: this,
      child: PrimaryScrollController(
        controller: _scrollController,
        child: ValueListenableBuilder<double>(
          valueListenable: _recede,
          child: ValueListenableBuilder<double>(
            valueListenable: _dragOffset,
            child: widget.child,
            builder: (BuildContext context, double offset, Widget? child) {
              return Transform.translate(
                offset: Offset(0, offset),
                child: child,
              );
            },
          ),
          builder: (BuildContext context, double depth, Widget? child) =>
              starSheetRecede(depth: depth, child: child!),
        ),
      ),
    );
  }
}

class _StarSheetDragTargetScope extends InheritedWidget {
  const _StarSheetDragTargetScope({
    required this.target,
    required super.child,
  });

  final StarSheetDragTarget target;

  static StarSheetDragTarget? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<_StarSheetDragTargetScope>()
        ?.target;
  }

  @override
  bool updateShouldNotify(_StarSheetDragTargetScope oldWidget) =>
      target != oldWidget.target;
}

class _StarSheetSurfaceScope extends InheritedWidget {
  const _StarSheetSurfaceScope({required super.child});

  static bool contains(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_StarSheetSurfaceScope>() !=
        null;
  }

  @override
  bool updateShouldNotify(_StarSheetSurfaceScope oldWidget) => false;
}

class _StarBottomSheetInsetChild extends StatelessWidget {
  const _StarBottomSheetInsetChild({
    required this.bottomPadding,
    required this.child,
  });

  final double bottomPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: child,
    );
  }
}

const double kStarSheetHandleTop = 8;
const double kStarSheetHandleGap = 18;
const double kStarSheetHandleWidth = 36;
const double kStarSheetHandleThickness = 4;
const double kStarSheetHandleHeight =
    kStarSheetHandleTop + kStarSheetHandleThickness + kStarSheetHandleGap;

const double _kSheetSizeEpsilon = 0.001;

class StarDraggableScrollableSheet extends StatefulWidget {
  const StarDraggableScrollableSheet({
    required this.minChildSize,
    required this.maxChildSize,
    required this.halfChildSize,
    required this.initialChildSize,
    required this.maxHeight,
    required this.fitContent,
    required this.showDragHandle,
    required this.hasHeader,
    required this.onDismiss,
    required this.navigator,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.trailing,
    required this.onBack,
    required this.bottomInset,
    required this.bottomScrollPadding,
    required this.sheetContext,
    required this.builder,
    super.key,
  });

  final double minChildSize;
  final double maxChildSize;
  final double halfChildSize;
  final double initialChildSize;
  final double maxHeight;
  final bool fitContent;
  final bool showDragHandle;
  final bool hasHeader;
  final VoidCallback onDismiss;
  final NavigatorState navigator;
  final String? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onBack;
  final double bottomInset;
  final double bottomScrollPadding;
  final BuildContext sheetContext;
  final StarScrollableBottomSheetBuilder builder;

  @override
  State<StarDraggableScrollableSheet> createState() =>
      _StarDraggableScrollableSheetState();
}

class _StarDraggableScrollableSheetState
    extends State<StarDraggableScrollableSheet>
    with SingleTickerProviderStateMixin
    implements StarSheetDragTarget {
  late final AnimationController _size = AnimationController.unbounded(
    vsync: this,
    value: widget.initialChildSize,
  )..addListener(_reportBackdrop);
  final ValueNotifier<double> _recede = ValueNotifier<double>(0);
  late final StarSheetScrollController _scrollController =
      StarSheetScrollController(
        this,
        dragsWhenShort: true,
        onContentExtent: widget.fitContent ? _handleContentExtent : null,
      );

  bool _dismissed = false;
  bool _routeDidEnter = false;
  bool _dragging = false;
  bool _fitScheduled = false;
  bool _shown = false;
  double _available = 0;
  double _layoutHeight = 0;
  double _contentHeight = 0;
  late double _restingSize = widget.initialChildSize;
  Animation<double>? _routeAnimation;
  StarSheetBackdropLink? _backdrop;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _shown = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_topSnapIsFull && _starSheetDrivesBackdrop(context)) {
      _backdrop ??= StarSheetBackdropLink(
        widget.navigator,
        route: ModalRoute.of(context),
        onCovered: _reportBackdrop,
      );
    } else {
      _backdrop?.dispose();
      _backdrop = null;
      _recede.value = 0;
    }
    _route = ModalRoute.of(context);
    final Animation<double>? animation = _route?.animation;
    if (identical(animation, _routeAnimation)) {
      return;
    }
    _routeAnimation
      ?..removeStatusListener(_markDismissedIfRouteClosing)
      ..removeListener(_reportBackdrop);
    _routeAnimation = animation;
    _routeAnimation
      ?..addStatusListener(_markDismissedIfRouteClosing)
      ..addListener(_reportBackdrop);
    final AnimationStatus? status = _routeAnimation?.status;
    if (status != null) {
      _markDismissedIfRouteClosing(status);
    }
  }

  @override
  void didUpdateWidget(StarDraggableScrollableSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bottomInset > oldWidget.bottomInset) {
      final bool opening = oldWidget.bottomInset <= 0;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _expandForKeyboard(animate: opening),
      );
    } else if (widget.bottomInset < oldWidget.bottomInset) {
      _scheduleFit();
    }
  }

  double get _maxSize {
    if (_contentHeight <= 0 || _available <= 0) {
      return widget.maxChildSize;
    }
    return math.min(
      widget.maxChildSize,
      (_contentHeight + widget.bottomInset) / _available,
    );
  }

  double get _halfSize => math.min(widget.halfChildSize, _maxSize);

  double get _restSize =>
      math.min(_halfSize, math.min(widget.initialChildSize, _maxSize));

  void _handleContentExtent(double viewportExtent, double contentExtent) {
    if ((contentExtent - viewportExtent).abs() < 0.5) {
      return;
    }
    final double height = _layoutHeight - viewportExtent + contentExtent;
    if (height <= _contentHeight + 0.5) {
      return;
    }
    _contentHeight = height;
    _scheduleFit(jump: !_shown);
  }

  void _scheduleFit({bool jump = false}) {
    if (_fitScheduled) {
      return;
    }
    _fitScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitScheduled = false;
      if (!mounted || _dismissed || _dragging) {
        return;
      }
      final double target = math.min(_restingSize, _maxSize);
      if ((_size.value - target).abs() >= _kSheetSizeEpsilon) {
        if (jump) {
          _size.value = target;
        } else {
          _moveTo(target);
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _routeAnimation
      ?..removeStatusListener(_markDismissedIfRouteClosing)
      ..removeListener(_reportBackdrop);
    _backdrop?.dispose();
    _size.dispose();
    _recede.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _topSnapIsFull =>
      widget.maxChildSize >= kStarBottomSheetFullSize - _kSheetSizeEpsilon &&
      widget.halfChildSize < widget.maxChildSize - _kSheetSizeEpsilon;

  void _expandForKeyboard({required bool animate}) {
    if (!mounted || _dismissed || _dragging || !canExpand) {
      return;
    }
    final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null ||
        focused
                .findAncestorStateOfType<
                  _StarDraggableScrollableSheetState
                >() !=
            this) {
      return;
    }
    _restingSize = _maxSize;
    if (animate) {
      _moveTo(_restingSize);
    } else {
      _size.value = _restingSize;
    }
  }

  void _moveTo(double target) {
    final StarMotionTheme motion = widget.sheetContext.motion;
    if (motion.panel <= Duration.zero) {
      _size.value = target;
      return;
    }
    _size.animateTo(target, duration: motion.panel, curve: motion.curve);
  }

  void _markDismissedIfRouteClosing(AnimationStatus status) {
    if (status == AnimationStatus.forward ||
        status == AnimationStatus.completed) {
      _routeDidEnter = true;
      return;
    }
    if (_routeDidEnter &&
        (status == AnimationStatus.reverse ||
            status == AnimationStatus.dismissed)) {
      _dismissed = true;
    }
  }

  void _reportBackdrop() {
    final ModalRoute<dynamic>? route = _route;
    final Animation<double>? animation = _routeAnimation;
    if (route == null || animation == null) {
      return;
    }
    final double restSize = _restSize;
    final double travel = restSize > 0
        ? (_size.value / restSize).clamp(0, 1)
        : 1;
    if (route is StarSheetRoute) {
      route.setScrimTravel(travel);
    }
    final StarSheetBackdropLink? backdrop = _backdrop;
    if (backdrop == null) {
      return;
    }
    final double fullness =
        ((_size.value - widget.halfChildSize) /
                (widget.maxChildSize - widget.halfChildSize))
            .clamp(0, 1);
    final double depth = backdrop.depth * fullness;
    _recede.value = depth;
    backdrop.report(
      starSheetBackdropProgress(animation, route.transitionDuration) *
          fullness *
          (1 + depth),
    );
  }

  void _dismiss() {
    if (_dismissed) {
      return;
    }
    _dismissed = true;
    if (!mounted) {
      return;
    }
    widget.onDismiss();
  }

  @override
  bool get canExpand => _size.value < _maxSize - _kSheetSizeEpsilon;

  @override
  void dragBy(double deltaDy) {
    if (_dismissed || _available <= 0) {
      return;
    }
    _dragging = true;
    if (deltaDy > 0 && MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _size.value = starBottomSheetSizeAfterDrag(
      currentSize: _size.value,
      deltaDy: deltaDy,
      availablePixels: _available,
      minChildSize: widget.minChildSize,
      maxChildSize: _maxSize,
    );
  }

  @override
  void endDrag(double velocityDy) {
    _dragging = false;
    if (_dismissed || _available <= 0) {
      return;
    }
    final double size = _size.value;
    final double? target = starBottomSheetSnapTarget(
      size: size,
      halfSize: _halfSize,
      fullSize: _maxSize,
      velocity: velocityDy,
      availablePixels: _available,
    );
    if (target == null) {
      _dismiss();
      return;
    }
    _restingSize = target;
    if ((size - target).abs() < _kSheetSizeEpsilon) {
      return;
    }
    _moveTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.sheetContext.layout;
    final Widget surface = _wrapBottomSheetSurface(
      context: widget.sheetContext,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomInset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double restHeight =
                _restSize * _available - widget.bottomInset;
            final double layoutHeight = math.max(
              constraints.maxHeight,
              math.max(
                restHeight,
                math.min(160, _maxSize * _available - widget.bottomInset),
              ),
            );
            _layoutHeight = layoutHeight;
            return OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: layoutHeight,
              maxHeight: layoutHeight,
              child: SizedBox(
                height: layoutHeight,
                child: Column(
                  children: [
                    if (widget.showDragHandle)
                      const StarBottomSheetDragHandle(),
                    if (!widget.showDragHandle && widget.hasHeader)
                      SizedBox(height: layout.s4),
                    if (widget.hasHeader)
                      _StarBottomSheetHeaderBlock(
                        title: widget.title ?? '',
                        subtitle: widget.subtitle,
                        leading: widget.leading,
                        trailing: widget.trailing,
                        onBack: widget.onBack,
                        gap: layout.s2,
                      ),
                    Expanded(
                      child: StarBottomSheetDragArea(
                        behavior: HitTestBehavior.translucent,
                        child: StarBottomSheetScope(
                          bottomScrollPadding: widget.bottomScrollPadding,
                          child: Builder(
                            builder: (scopedContext) => widget.builder(
                              scopedContext,
                              _scrollController,
                              _dismiss,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    return _StarSheetDragTargetScope(
      target: this,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _available = math.min(widget.maxHeight, constraints.maxHeight);
          return ValueListenableBuilder<double>(
            valueListenable: _recede,
            child: AnimatedBuilder(
              animation: _size,
              child: surface,
              builder: (BuildContext context, Widget? child) => SizedBox(
                height: math.max(0, _size.value * _available),
                child: child,
              ),
            ),
            builder: (BuildContext context, double depth, Widget? child) =>
                starSheetRecede(depth: depth, child: child!),
          );
        },
      ),
    );
  }
}

class StarBottomSheetDragArea extends StatefulWidget {
  const StarBottomSheetDragArea({
    required this.child,
    super.key,
    this.onDismiss,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onDismiss;
  final HitTestBehavior behavior;

  @override
  State<StarBottomSheetDragArea> createState() =>
      _StarBottomSheetDragAreaState();
}

class _StarBottomSheetDragAreaState extends State<StarBottomSheetDragArea> {
  double _dragDistance = 0;

  StarSheetDragTarget? get _target =>
      _StarSheetDragTargetScope.maybeOf(context);

  bool get _canDrag => _target != null || widget.onDismiss != null;

  void _handleVerticalDragStart(DragStartDetails details) {
    _dragDistance = 0;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final StarSheetDragTarget? target = _target;
    if (target != null) {
      target.dragBy(details.delta.dy);
      return;
    }
    _dragDistance += details.delta.dy;
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    final StarSheetDragTarget? target = _target;
    if (target != null) {
      target.endDrag(velocity);
      return;
    }
    final double distance = _dragDistance;
    _dragDistance = 0;
    if (starBottomSheetShouldDismissAfterDrag(
      dragDistance: distance,
      velocity: velocity,
      sheetHeight: context.size?.height ?? double.infinity,
    )) {
      widget.onDismiss?.call();
    }
  }

  void _handleVerticalDragCancel() {
    _target?.endDrag(0);
  }

  @override
  Widget build(BuildContext context) {
    return StarGestureDetector(
      behavior: widget.behavior,
      onVerticalDragStart: _canDrag ? _handleVerticalDragStart : null,
      onVerticalDragUpdate: _canDrag ? _handleVerticalDragUpdate : null,
      onVerticalDragEnd: _canDrag ? _handleVerticalDragEnd : null,
      onVerticalDragCancel: _canDrag ? _handleVerticalDragCancel : null,
      child: widget.child,
    );
  }
}

class StarBottomSheetDragHandle extends StatelessWidget {
  const StarBottomSheetDragHandle({super.key, this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return StarBottomSheetDragArea(
      onDismiss: onDismiss,
      child: const SizedBox(
        height: kStarSheetHandleHeight,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: kStarSheetHandleTop),
            child: StarSheetHandleBar(),
          ),
        ),
      ),
    );
  }
}

class StarSheetHandleBar extends StatelessWidget {
  const StarSheetHandleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kStarSheetHandleWidth,
      height: kStarSheetHandleThickness,
      decoration: BoxDecoration(
        color: context.colors.backgroundModifierAccent,
        borderRadius: BorderRadius.circular(kStarSheetHandleThickness / 2),
      ),
    );
  }
}

class _StarBottomSheetHeaderBlock extends StatelessWidget {
  const _StarBottomSheetHeaderBlock({
    required this.title,
    required this.gap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onBack,
  });

  final String title;
  final double gap;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return StarBottomSheetDragArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarBottomSheetHeader(
            title: title,
            subtitle: subtitle,
            leading: leading,
            trailing: trailing,
            onBack: onBack,
          ),
          SizedBox(height: gap),
        ],
      ),
    );
  }
}

class StarBottomSheetHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget? after;

  const StarBottomSheetHeader({
    required this.title,
    super.key,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.after,
  });

  bool _leadingOccupiesSpace(Widget? widget) {
    if (widget == null) {
      return false;
    }
    if (widget is SizedBox) {
      final double? width = widget.width;
      final double? height = widget.height;
      if (widget.child == null &&
          (width == null || width == 0) &&
          (height == null || height == 0)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final Widget? effectiveLeading = onBack != null
        ? IconButton(
            onPressed: onBack,
            tooltip: l10n.back,
            icon: PhosphorIcon(
              PhosphorIconsBold.caretLeft,
              size: 20,
              color: colors.textPrimary,
            ),
          )
        : _leadingOccupiesSpace(leading)
        ? leading
        : null;

    final bool inMenu = StarDesktopSurfaceScope.isMenu(context);
    final bool inModal =
        StarDesktopSurfaceScope.maybeOf(context) ==
        StarDesktopSurface.modal;
    final bool alignStart =
        inMenu || inModal || effectiveLeading != null || trailing != null;

    return Padding(
      padding: inMenu
          ? const EdgeInsets.fromLTRB(8, 4, 8, 6)
          : EdgeInsets.symmetric(horizontal: layout.pageGutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (effectiveLeading != null) ...[
                effectiveLeading,
                SizedBox(width: layout.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: alignStart
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: inMenu
                          ? starDesktopMenuLabelStyle(context).copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            )
                          : inModal
                          ? context.textStyles.channelName.copyWith(
                              color: colors.textPrimary,
                              fontSize: 18,
                              height: 20 / 18,
                            )
                          : context.textStyles.channelName.copyWith(
                              color: colors.textPrimary,
                            ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: alignStart
                          ? TextAlign.start
                          : TextAlign.center,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle.merge(
                        textAlign: alignStart
                            ? TextAlign.start
                            : TextAlign.center,
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[SizedBox(width: layout.s3), trailing!],
            ],
          ),
          if (after != null) ...[SizedBox(height: layout.s3), after!],
        ],
      ),
    );
  }
}

class StarBottomSheetSubmenuHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const StarBottomSheetSubmenuHeader({
    required this.title,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StarBottomSheetHeader(title: title, onBack: onBack);
  }
}

class StarBottomSheetContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const StarBottomSheetContent({
    required this.child,
    super.key,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final EdgeInsets resolvedPadding = StarBottomSheet.scrollViewPadding(
      context,
      padding: padding ?? EdgeInsets.symmetric(horizontal: layout.pageGutter),
    );

    if (!scrollable) {
      return Padding(padding: resolvedPadding, child: child);
    }

    return SingleChildScrollView(padding: resolvedPadding, child: child);
  }
}

class StarBottomSheetSection extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const StarBottomSheetSection({
    required this.child,
    super.key,
    this.title,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    if (StarDesktopSurfaceScope.isMenu(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) StarDesktopMenuGroupLabel(label: title!),
          child,
        ],
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: layout.pageGutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.only(bottom: layout.s2),
              child: Text(
                title!,
                style: context.textStyles.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class StarBottomSheetFooter extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showTopBorder;

  const StarBottomSheetFooter({
    required this.child,
    super.key,
    this.padding,
    this.showTopBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    final bool inScrollableSheet =
        StarBottomSheetScope.maybeOf(context) != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showTopBorder
            ? Border(
                top: BorderSide(
                  color: colors.backgroundModifierAccent.withValues(alpha: 0.5),
                ),
              )
            : null,
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        maintainBottomViewPadding: inScrollableSheet,
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: layout.pageGutter,
                vertical: layout.s4,
              ),
          child: child,
        ),
      ),
    );
  }
}

class StarMenuGroup extends StatelessWidget {
  final List<Widget> children;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool roundedRows;

  const StarMenuGroup({
    required this.children,
    this.color,
    this.borderRadius,
    this.roundedRows = false,
    super.key,
  });

  static bool isGrouped(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_StarMenuGroupScope>() !=
      null;

  static Widget ensureGrouped(BuildContext context, Widget row) =>
      isGrouped(context) ? row : StarMenuGroup(children: [row]);

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final layout = context.layout;

    if (roundedRows || StarDesktopSurfaceScope.isMenu(context)) {
      return _StarMenuGroupScope(
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      );
    }

    return Material(
      color: color ?? StarBottomSheet.cardColorOf(context),
      surfaceTintColor: Colors.transparent,
      borderRadius: borderRadius ?? layout.radiusXxl,
      clipBehavior: Clip.antiAlias,
      child: _StarMenuGroupScope(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _intersperseDividers(
            children,
            dividerColor: context.colors.backgroundModifierAccent,
            dividerInset: layout.groupRowInset,
          ),
        ),
      ),
    );
  }
}

class _StarMenuGroupScope extends InheritedWidget {
  const _StarMenuGroupScope({required super.child});

  @override
  bool updateShouldNotify(_StarMenuGroupScope oldWidget) => false;
}

List<Widget> _intersperseDividers(
  List<Widget> items, {
  required Color dividerColor,
  required double dividerInset,
}) {
  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(items[i]);
    if (i < items.length - 1) {
      result.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: dividerInset),
          child: Divider(height: 1, thickness: 1, color: dividerColor),
        ),
      );
    }
  }
  return result;
}

class StarBottomSheetMenuItem extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback onTap;
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  final bool isDanger;
  final bool isSelected;
  final bool enabled;
  final Widget? trailing;
  final bool? toggled;
  final Color? labelColor;
  final bool dense;
  final Widget? labelBadge;

  const StarBottomSheetMenuItem({
    required this.label,
    required this.onTap,
    super.key,
    this.hint,
    this.leading,
    this.icon,
    this.iconColor,
    this.isDanger = false,
    this.isSelected = false,
    this.enabled = true,
    this.trailing,
    this.toggled,
    this.labelColor,
    this.dense = false,
    this.labelBadge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseColor =
        labelColor ?? (isDanger ? colors.menuDangerText : colors.textPrimary);

    if (StarDesktopSurfaceScope.isMenu(context)) {
      return _buildDesktopRow(context);
    }

    return StarTappable(
      enabled: enabled,
      onTap: onTap,
      selected: isSelected,
      toggled: toggled,
      semanticLabel: hint != null ? '$label. $hint' : label,
      excludeChildSemantics: true,
      builder: (context, states) {
        final isPressed = states.contains(WidgetState.pressed);
        final isHovered = states.contains(WidgetState.hovered);

        final layout = context.layout;
        final double rowMinHeight = dense ? kSidebarPeekMenuRowHeight : 56;
        final double rowVerticalPadding = dense
            ? kSidebarPeekMenuItemVerticalPadding
            : 14;
        final double iconBoxSize = dense ? kSidebarPeekMenuItemIconSize : 20;
        final double iconSize = dense ? kSidebarPeekMenuItemIconSize : 20;
        final double rowGap = dense ? kSidebarPeekMenuItemRowGap : 12;
        final Color rowIconColor = iconColor ?? baseColor;
        final Widget? rowIcon = switch ((leading, icon)) {
          (final Widget leadingWidget, _) => IconTheme.merge(
            data: IconThemeData(color: rowIconColor, size: iconSize),
            child: leadingWidget,
          ),
          (_, final IconData iconData) => PhosphorIcon(
            iconData,
            color: rowIconColor,
            size: iconSize,
          ),
          _ => null,
        };

        final BoxDecoration? rowDecoration = dense
            ? BoxDecoration(
                color: isPressed
                    ? colors.listItemPressedBg
                    : isHovered && enabled
                    ? colors.backgroundModifierHover
                    : Colors.transparent,
                borderRadius: layout.radiusXl,
              )
            : null;

        return AnimatedContainer(
          duration: context.motion.fast,
          curve: context.motion.curve,
          margin: dense
              ? EdgeInsets.symmetric(
                  horizontal: layout.s2,
                  vertical: kSidebarPeekMenuItemVerticalMargin,
                )
              : null,
          decoration: rowDecoration,
          color: dense
              ? null
              : (isPressed
                    ? colors.listItemPressedBg
                    : isHovered
                    ? colors.backgroundModifierHover
                    : Colors.transparent),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: rowMinHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: layout.groupRowInset,
                vertical: rowVerticalPadding,
              ),
              child: Row(
                children: [
                  if (rowIcon != null) ...[
                    SizedBox(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      child: Center(child: rowIcon),
                    ),
                    SizedBox(width: rowGap),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StarLabelWithBadge(
                          badge: labelBadge,
                          label: Text(
                            label,
                            style: context.textStyles.username.copyWith(
                              color: enabled ? baseColor : colors.textTertiary,
                            ),
                            maxLines: dense ? 1 : null,
                            overflow: dense ? TextOverflow.ellipsis : null,
                          ),
                        ),
                        if (hint != null)
                          Text(
                            hint!,
                            style: context.textStyles.timestamp.copyWith(
                              color: colors.textTertiary,
                            ),
                            maxLines: dense ? 1 : null,
                            overflow: dense ? TextOverflow.ellipsis : null,
                          ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: rowGap),
                    trailing!,
                  ] else if (isSelected) ...[
                    SizedBox(width: rowGap),
                    const StarSelectedCheck(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopRow(BuildContext context) {
    final colors = context.colors;
    final Color baseColor =
        labelColor ??
        (!enabled
            ? colors.interactiveMuted
            : isDanger
            ? starDesktopMenuDangerText(colors)
            : colors.textPrimary);
    final Widget? iconWidget = icon == null
        ? null
        : PhosphorIcon(
            icon!,
            color: iconColor ?? baseColor,
            size: kStarDesktopMenuIconSize,
          );
    return StarDesktopMenuRow(
      label: label,
      hint: hint,
      onTap: onTap,
      isDanger: isDanger,
      enabled: enabled,
      selected: isSelected,
      toggled: toggled,
      labelColor: labelColor,
      leading: leading,
      trailing:
          trailing ??
          (isSelected ? const StarSelectedCheck() : null) ??
          iconWidget,
    );
  }
}

class StarBottomSheetSubmenuItem extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback onTap;

  const StarBottomSheetSubmenuItem({
    required this.label,
    required this.onTap,
    this.hint,
    this.icon,
    this.leading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StarBottomSheetMenuItem(
      label: label,
      hint: hint,
      icon: icon,
      leading: leading,
      onTap: onTap,
      trailing: StarDesktopSurfaceScope.isMenu(context)
          ? PhosphorIcon(
              PhosphorIconsBold.caretRight,
              size: kStarDesktopMenuCaretSize,
              color: context.colors.textTertiary,
            )
          : PhosphorIcon(
              PhosphorIconsBold.caretRight,
              size: 16,
              color: context.colors.textSecondary,
            ),
    );
  }
}

class StarBottomSheetMenuRadioItem extends StatelessWidget {
  const StarBottomSheetMenuRadioItem({
    required this.label,
    required this.onTap,
    required this.isSelected,
    super.key,
    this.hint,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final VoidCallback onTap;
  final bool isSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final StarColorTheme colors = context.colors;

    if (StarDesktopSurfaceScope.isMenu(context)) {
      return StarDesktopMenuRow(
        label: label,
        hint: hint,
        onTap: onTap,
        enabled: enabled,
        selected: isSelected,
        trailing: StarRadioIndicator(selected: isSelected),
      );
    }

    return StarTappable(
      enabled: enabled,
      onTap: onTap,
      semanticLabel: hint != null ? '$label. $hint' : label,
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) {
        final bool isPressed = states.contains(WidgetState.pressed);
        final bool isHovered = states.contains(WidgetState.hovered);

        return AnimatedContainer(
          duration: context.motion.fast,
          curve: context.motion.curve,
          color: isPressed
              ? colors.listItemPressedBg
              : isHovered
              ? colors.backgroundModifierHover
              : Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.layout.groupRowInset,
                vertical: 14,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          label,
                          style: context.textStyles.username.copyWith(
                            color: enabled
                                ? colors.textPrimary
                                : colors.textTertiary,
                          ),
                        ),
                        if (hint != null)
                          Text(
                            hint!,
                            style: context.textStyles.timestamp.copyWith(
                              color: colors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  StarRadioIndicator(selected: isSelected),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class StarBottomSheetGroupColumn extends StatelessWidget {
  final List<Widget> children;

  const StarBottomSheetGroupColumn({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final bool inMenu = StarDesktopSurfaceScope.isMenu(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: inMenu
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1 && inMenu)
            const StarDesktopMenuSeparator()
          else if (i < children.length - 1)
            const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class StarBottomSheetCheckboxItem extends StatelessWidget {
  final String label;
  final bool isChecked;
  final VoidCallback onTap;

  const StarBottomSheetCheckboxItem({
    required this.label,
    required this.isChecked,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (StarDesktopSurfaceScope.isMenu(context)) {
      return StarDesktopMenuRow(
        label: label,
        onTap: onTap,
        checked: isChecked,
        trailing: StarDesktopMenuCheckbox(isChecked: isChecked),
      );
    }

    return StarTappable(
      onTap: onTap,
      semanticLabel: label,
      checked: isChecked,
      excludeChildSemantics: true,
      builder: (context, states) {
        return Container(
          constraints: const BoxConstraints(minHeight: 56),
          color: states.contains(WidgetState.hovered)
              ? colors.backgroundModifierHover
              : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.layout.groupRowInset,
              vertical: 14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: context.textStyles.username.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isChecked
                          ? colors.brandPrimary
                          : colors.backgroundHeaderSecondary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: isChecked ? colors.brandPrimary : Colors.transparent,
                  ),
                  child: isChecked
                      ? Center(
                          child: PhosphorIcon(
                            PhosphorIconsBold.check,
                            size: 12,
                            color: colors.textOnBrandPrimary,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

@StarWidgetPreview(name: 'Drag handle', group: 'StarBottomSheet')
Widget starBottomSheetDragHandlePreview() {
  return const StarBottomSheetDragHandle();
}

@StarWidgetPreview(name: 'Header', group: 'StarBottomSheet')
Widget starBottomSheetHeaderPreview() {
  return const StarBottomSheetHeader(
    title: 'Invite friends',
    subtitle: Text('Share this server with people you trust.'),
  );
}

@StarWidgetPreview(name: 'Submenu header', group: 'StarBottomSheet')
Widget starBottomSheetSubmenuHeaderPreview() {
  return StarBottomSheetSubmenuHeader(
    title: 'Notification settings',
    onBack: () {},
  );
}

@StarWidgetPreview(name: 'Content', group: 'StarBottomSheet')
Widget starBottomSheetContentPreview() {
  return const StarBottomSheetContent(
    scrollable: false,
    child: Text('Sheet body content goes here.'),
  );
}

@StarWidgetPreview(name: 'Section', group: 'StarBottomSheet')
Widget starBottomSheetSectionPreview() {
  return const StarBottomSheetSection(
    title: 'Privacy',
    child: Text('Section children'),
  );
}

@StarWidgetPreview(name: 'Footer', group: 'StarBottomSheet')
Widget starBottomSheetFooterPreview() {
  return StarBottomSheetFooter(
    showTopBorder: true,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () {}, child: const Text('Cancel')),
        const SizedBox(width: 8),
        FilledButton(onPressed: () {}, child: const Text('Save')),
      ],
    ),
  );
}

@StarWidgetPreview(name: 'Menu group', group: 'StarBottomSheet')
Widget starBottomSheetMenuGroupPreview() {
  return StarMenuGroup(
    children: [
      StarBottomSheetMenuItem(
        label: 'Edit channel',
        icon: PhosphorIconsBold.pencilSimple,
        onTap: () {},
      ),
      StarBottomSheetMenuItem(
        label: 'Delete channel',
        hint: 'Cannot be undone',
        icon: PhosphorIconsBold.trash,
        isDanger: true,
        onTap: () {},
      ),
    ],
  );
}

@StarWidgetPreview(name: 'Menu item selected', group: 'StarBottomSheet')
Widget starBottomSheetMenuItemSelectedPreview() {
  return StarBottomSheetMenuItem(
    label: 'Dark',
    isSelected: true,
    onTap: () {},
  );
}

@StarWidgetPreview(name: 'Submenu item', group: 'StarBottomSheet')
Widget starBottomSheetSubmenuItemPreview() {
  return StarBottomSheetSubmenuItem(
    label: 'Change nickname',
    onTap: () {},
    icon: PhosphorIconsBold.user,
  );
}

@StarWidgetPreview(name: 'Checkbox item', group: 'StarBottomSheet')
Widget starBottomSheetCheckboxItemPreview() {
  return StarBottomSheetCheckboxItem(
    label: 'Mute @mentions',
    isChecked: true,
    onTap: () {},
  );
}

@StarWidgetPreview(name: 'Group column', group: 'StarBottomSheet')
Widget starBottomSheetGroupColumnPreview() {
  return StarBottomSheetGroupColumn(
    children: [
      StarBottomSheetMenuItem(label: 'First', onTap: () {}),
      StarBottomSheetMenuItem(label: 'Second', onTap: () {}),
    ],
  );
}
