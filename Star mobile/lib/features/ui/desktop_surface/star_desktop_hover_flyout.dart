part of 'star_desktop_surface.dart';

class StarDesktopHoverFlyout extends StatefulWidget {
  const StarDesktopHoverFlyout({
    required this.child,
    required this.flyoutBuilder,
    this.width = kStarDesktopMenuDefaultWidth,
    super.key,
  });

  final Widget child;
  final WidgetBuilder flyoutBuilder;
  final double width;

  @override
  State<StarDesktopHoverFlyout> createState() =>
      _StarDesktopHoverFlyoutState();
}

class _StarDesktopHoverFlyoutState extends State<StarDesktopHoverFlyout> {
  final OverlayPortalController _portal = OverlayPortalController();
  Timer? _closeTimer;
  Rect? _anchor;

  _StarDesktopHoverFlyoutState? get _parent =>
      context.getInheritedWidgetOfExactType<_FlyoutParentScope>()?.flyout;

  void _open() {
    _keepOpen();
    if (_portal.isShowing) {
      return;
    }
    final Rect? anchor = starDesktopWidgetRectOf(
      context,
      navigator: Navigator.of(context),
    );
    if (anchor == null) {
      return;
    }
    _anchor = anchor;
    _portal.show();
  }

  void _keepOpen() {
    _closeTimer?.cancel();
    _parent?._keepOpen();
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(_kFlyoutCloseDelay, () {
      if (mounted && _portal.isShowing) {
        _portal.hide();
      }
    });
    _parent?._scheduleClose();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  Widget _buildFlyout(BuildContext context) {
    return _FlyoutParentScope(
      flyout: this,
      child: CustomSingleChildLayout(
        delegate: StarDesktopAnchoredLayoutDelegate(
          posture: deviceFoldPostureOf(context),
          anchor: _anchor,
          placement: StarDesktopPlacement.rightStart,
        ),
        child: MouseRegion(
          onEnter: (_) => _keepOpen(),
          onExit: (_) => _scheduleClose(),
          child: StarDesktopMenuPanel(
            width: widget.width,
            child: Builder(builder: widget.flyoutBuilder),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildFlyout,
      child: MouseRegion(
        onEnter: (_) => _open(),
        onExit: (_) => _scheduleClose(),
        child: widget.child,
      ),
    );
  }
}

class _FlyoutParentScope extends InheritedWidget {
  const _FlyoutParentScope({required this.flyout, required super.child});

  final _StarDesktopHoverFlyoutState flyout;

  @override
  bool updateShouldNotify(_FlyoutParentScope oldWidget) =>
      flyout != oldWidget.flyout;
}
