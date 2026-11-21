import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/bookmarks/presentation/widgets/saved_messages_body.dart';
import 'package:star_app/features/notifications/data/notifications_repository.dart';
import 'package:star_app/features/notifications/domain/unread_inbox_entry.dart';
import 'package:star_app/features/notifications/presentation/widgets/mention_filters_sheet.dart';
import 'package:star_app/features/notifications/presentation/widgets/notifications_mentions_body.dart';
import 'package:star_app/features/notifications/presentation/widgets/notifications_unreads_body.dart';
import 'package:star_app/features/notifications/providers/notifications_providers.dart';
import 'package:star_app/features/settings/providers/preferences/advanced_preferences_provider.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/settings/star_settings_confirm_sheet.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

enum InboxTab { unreads, bookmarks, mentions }

typedef InboxPopoutAnchorBuilder =
    Widget Function(
      BuildContext context, {
      required bool isOpen,
      required VoidCallback toggle,
    });

class InboxPopoutButton extends StatefulWidget {
  const InboxPopoutButton({required this.anchorBuilder, super.key});

  final InboxPopoutAnchorBuilder anchorBuilder;

  @override
  State<InboxPopoutButton> createState() => _InboxPopoutButtonState();
}

class _InboxPopoutButtonState extends State<InboxPopoutButton>
    with SingleTickerProviderStateMixin {
  static const double _kDefaultHeight = 900;
  static const double _kDefaultWidth = 600;
  static const double _kMinHeight = 400;
  static const double _kViewportPadding = 16;
  static const double _kAnchorGap = 8;

  final OverlayPortalController _overlayController = OverlayPortalController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: StarMotionTheme.normalDuration,
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
      return;
    }
    setState(_overlayController.show);
    _animationController.forward();
  }

  void _close() {
    unawaited(
      _animationController.reverse().then((_) {
        if (mounted && _overlayController.isShowing) {
          setState(_overlayController.hide);
        }
      }),
    );
  }

  Widget _buildOverlay(BuildContext context, OverlayChildLayoutInfo info) {
    final StarColorTheme colors = context.colors;
    final StarLayoutTheme layout = context.layout;
    final bool desktop = usesDesktopPointerUi(context);
    final EdgeInsets insets = MediaQuery.paddingOf(context);
    final Size overlay = info.overlaySize;
    final Rect anchor = MatrixUtils.transformRect(
      info.childPaintTransform,
      Offset.zero & info.childSize,
    );

    final double minLeft = insets.left + _kViewportPadding;
    final double maxRight = overlay.width - insets.right - _kViewportPadding;
    final double minTop = insets.top + _kViewportPadding;
    final double maxBottom = overlay.height - insets.bottom - _kViewportPadding;

    final double width = math.max(
      0,
      math.min(_kDefaultWidth, maxRight - minLeft),
    );
    final double desiredHeight = math.max(
      0,
      math.min(_kDefaultHeight, maxBottom - minTop),
    );
    final double spaceBelow = maxBottom - anchor.bottom - _kAnchorGap;
    final double spaceAbove = anchor.top - _kAnchorGap - minTop;
    final bool openUpward =
        spaceBelow < math.min(desiredHeight, _kMinHeight) &&
        spaceAbove > spaceBelow;
    final double height = math.max(
      0,
      math.min(desiredHeight, openUpward ? spaceAbove : spaceBelow),
    );
    final double preferredLeft = Directionality.of(context) == TextDirection.rtl
        ? anchor.left
        : anchor.right - width;
    final double left = math.max(
      minLeft,
      math.min(preferredLeft, maxRight - width),
    );
    final double top = openUpward
        ? anchor.top - _kAnchorGap - height
        : anchor.bottom + _kAnchorGap;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: StarGestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: desktop
                    ? starFormSurfaceBackground(context)
                    : colors.backgroundSecondary,
                borderRadius: layout.radiusLg,
                border: Border.all(color: colors.backgroundModifierAccent),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: layout.radiusLg,
                child: InboxPopout(onClose: _close),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOpen = _overlayController.isShowing;
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _overlayController,
      overlayChildBuilder: _buildOverlay,
      child: widget.anchorBuilder(context, isOpen: isOpen, toggle: _toggle),
    );
  }
}

class InboxPopout extends ConsumerStatefulWidget {
  const InboxPopout({this.onClose, super.key});

  final VoidCallback? onClose;

  @override
  ConsumerState<InboxPopout> createState() => _InboxPopoutState();
}

class _InboxPopoutState extends ConsumerState<InboxPopout> {
  static const double _kSidebarWidth = 46;

  InboxTab _activeTab = InboxTab.unreads;
  Future<void> _confirmAndMarkAllAsRead() async {
    final bool skipConfirmation = ref.read(
      advancedPreferencesProvider.select(
        (state) => state.skipMarkAllAsReadConfirmation,
      ),
    );
    if (!skipConfirmation) {
      final bool? confirmed = await showStarSettingsConfirmSheet(
        context,
        title: StarLocalizations.of(context).notificationsMarkAsRead,
        description: StarLocalizations.of(
          context,
        ).advancedSettingSkipMarkAllAsReadDescription,
        confirmLabel: StarLocalizations.of(context).notificationsMarkAsRead,
      );
      if (confirmed != true || !mounted) {
        return;
      }
    }
    await _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    final List<UnreadInboxEntry> entries = await ref.read(
      unreadInboxChannelListProvider.future,
    );
    if (entries.isEmpty || !mounted) {
      return;
    }
    final NotificationsRepository repo = ref.read(
      notificationsRepositoryProvider,
    );
    await repo.markAllInboxChannelsAsRead(entries);
    ref.invalidate(unreadInboxChannelListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final StarColorTheme colors = context.colors;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final AsyncValue<List<UnreadInboxEntry>> unreadAsync = ref.watch(
      unreadInboxChannelListProvider,
    );
    final bool canMarkAllRead = unreadAsync.maybeWhen(
      data: (List<UnreadInboxEntry> list) => list.isNotEmpty,
      orElse: () => false,
    );
    final bool desktop = usesDesktopPointerUi(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: desktop
                ? starFormSurfaceBackground(context)
                : colors.backgroundSecondary,
            border: BorderDirectional(
              end: BorderSide(color: colors.backgroundModifierAccent),
            ),
          ),
          child: SizedBox(
            width: _kSidebarWidth,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                _InboxSidebarTab(
                  tooltip: l10n.notificationsFilterUnreads,
                  icon: PhosphorIconsFill.bell,
                  isActive: _activeTab == InboxTab.unreads,
                  onTap: () => setState(() => _activeTab = InboxTab.unreads),
                ),
                const SizedBox(height: 8),
                _InboxSidebarTab(
                  tooltip: l10n.notificationsBookmarksTooltip,
                  icon: desktop
                      ? PhosphorIconsRegular.bookmarkSimple
                      : PhosphorIconsBold.bookmarkSimple,
                  isActive: _activeTab == InboxTab.bookmarks,
                  onTap: () => setState(() => _activeTab = InboxTab.bookmarks),
                ),
                const SizedBox(height: 8),
                _InboxSidebarTab(
                  tooltip: l10n.notificationsFilterMentions,
                  icon: desktop ? PhosphorIconsBold.at : PhosphorIconsFill.at,
                  isActive: _activeTab == InboxTab.mentions,
                  onTap: () => setState(() => _activeTab = InboxTab.mentions),
                ),
                const Spacer(),
                if (_activeTab == InboxTab.mentions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: StarTooltip(
                      message: l10n.notificationsMentionFilterTooltip,
                      position: StarTooltipPosition.right,
                      child: _InboxSidebarActionButton(
                        icon: PhosphorIconsBold.funnel,
                        label: l10n.notificationsMentionFilterTooltip,
                        onPressed: () => unawaited(
                          showMentionFiltersSheet(
                            context,
                            title: l10n.notificationsMentionFiltersTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_activeTab == InboxTab.unreads)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: StarTooltip(
                      message: l10n.notificationsMarkAsRead,
                      position: StarTooltipPosition.right,
                      child: _InboxSidebarActionButton(
                        icon: PhosphorIconsBold.check,
                        label: l10n.notificationsMarkAsRead,
                        onPressed: canMarkAllRead
                            ? () => unawaited(_confirmAndMarkAllAsRead())
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: switch (_activeTab) {
            InboxTab.unreads => const NotificationsUnreadsBody(),
            InboxTab.bookmarks => SavedMessagesBody(onClose: widget.onClose),
            InboxTab.mentions => const NotificationsMentionsBody(),
          },
        ),
      ],
    );
  }
}

class _InboxSidebarTab extends StatelessWidget {
  const _InboxSidebarTab({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final StarColorTheme colors = context.colors;
    if (!usesDesktopPointerUi(context)) {
      return StarTooltip(
        message: tooltip,
        position: StarTooltipPosition.right,
        child: _InboxTouchIconButton(
          icon: icon,
          onTap: onTap,
          isActive: isActive,
        ),
      );
    }
    return StarTooltip(
      message: tooltip,
      position: StarTooltipPosition.right,
      child: StarTappable(
        selected: isActive,
        onTap: onTap,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          return AnimatedContainer(
            duration: context.motion.fast,
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive
                  ? colors.backgroundModifierSelected
                  : hovered
                  ? colors.backgroundModifierHover
                  : Colors.transparent,
              borderRadius: context.layout.radiusMd,
            ),
            child: PhosphorIcon(
              icon,
              size: 16,
              color: isActive || hovered
                  ? colors.textPrimary
                  : colors.textPrimaryMuted,
            ),
          );
        },
      ),
    );
  }
}

class _InboxSidebarActionButton extends StatelessWidget {
  const _InboxSidebarActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (usesDesktopPointerUi(context)) {
      return StarButton.desktop(
        icon: icon,
        semanticLabel: label,
        extent: 30,
        borderRadius: 6,
        duration: Duration.zero,
        onPressed: onPressed,
      );
    }
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: _InboxTouchIconButton(icon: icon, onTap: onPressed),
    );
  }
}

class _InboxTouchIconButton extends StatelessWidget {
  const _InboxTouchIconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final StarColorTheme colors = context.colors;
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        hoverColor: enabled ? colors.backgroundModifierHover : null,
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive
                  ? colors.backgroundModifierSelected
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: PhosphorIcon(
              icon,
              size: 16,
              color: isActive ? colors.textPrimary : colors.textPrimaryMuted,
            ),
          ),
        ),
      ),
    );
  }
}
