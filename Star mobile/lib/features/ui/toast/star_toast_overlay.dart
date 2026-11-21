import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_motion_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/foldable/crease_overlay_layout.dart';
import 'package:star_app/features/ui/tappable/star_gesture_detector.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class StarToastOverlay extends ConsumerWidget {
  const StarToastOverlay({required this.child, super.key});

  final Widget child;

  IconData? _variantIcon(StarToastVariant variant) => switch (variant) {
    StarToastVariant.success => PhosphorIconsBold.check,
    StarToastVariant.danger => PhosphorIconsBold.x,
    StarToastVariant.warning => PhosphorIconsBold.warning,
    StarToastVariant.info => null,
  };

  Color _variantIconColor(
    BuildContext context,
    StarToastVariant variant, {
    required bool desktop,
  }) {
    final colors = context.colors;
    return switch (variant) {
      StarToastVariant.success =>
        desktop ? colors.statusOnline : colors.accentSuccess,
      StarToastVariant.danger =>
        desktop ? colors.statusDanger : colors.accentDanger,
      StarToastVariant.warning => colors.accentWarning,
      StarToastVariant.info => colors.textPrimary,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(toastProvider);
    final layout = context.layout;
    final mediaQuery = MediaQuery.of(context);
    final bool desktop = usesDesktopPointerUi(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (entries.isNotEmpty)
          Positioned(
            left: layout.s4,
            right: layout.s4,
            top: mediaQuery.padding.top + (desktop ? layout.s6 : layout.s4),
            child: CreaseAwareAlign(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in entries)
                    Padding(
                      padding: EdgeInsets.only(bottom: layout.s2),
                      child: _ToastItem(
                        key: ValueKey<int>(entry.id),
                        entry: entry,
                        desktop: desktop,
                        icon: entry.toast.leading == null
                            ? _variantIcon(entry.toast.variant)
                            : null,
                        iconColor: _variantIconColor(
                          context,
                          entry.toast.variant,
                          desktop: desktop,
                        ),
                        onDismiss: () =>
                            ref.read(toastProvider.notifier).dismiss(entry.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ToastItem extends StatefulWidget {
  const _ToastItem({
    required this.entry,
    required this.icon,
    required this.iconColor,
    required this.onDismiss,
    this.desktop = false,
    super.key,
  });

  final ToastEntry entry;
  final bool desktop;
  final IconData? icon;
  final Color iconColor;
  final VoidCallback onDismiss;

  @override
  State<_ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends State<_ToastItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: StarMotionTheme.panelDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (widget.entry.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.motion.panel;
  }

  @override
  void didUpdateWidget(covariant _ToastItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.isVisible == oldWidget.entry.isVisible) {
      return;
    }
    if (widget.entry.isVisible) {
      _controller.forward();
      return;
    }
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runAction(StarToastAction action) {
    widget.onDismiss();
    action.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String message = widget.entry.toast.message;
    final StarToastAction? action = widget.entry.toast.action;
    final Widget? leading = widget.entry.toast.leading;
    final bool centerMessage = message.contains('\n') && leading != null;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: IgnorePointer(
          ignoring: !widget.entry.isVisible,
          child: Semantics(
            liveRegion: true,
            label: message,
            button: true,
            onTap: widget.onDismiss,
            hint: l10n.uiDismissNotification,
            customSemanticsActions: action == null
                ? null
                : <CustomSemanticsAction, VoidCallback>{
                    CustomSemanticsAction(label: action.label): () =>
                        _runAction(action),
                  },
            child: ExcludeSemantics(
              child: StarGestureDetector(
                onTap: widget.onDismiss,
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: widget.desktop
                          ? MediaQuery.sizeOf(context).width * 0.9
                          : 400,
                    ),
                    padding: widget.desktop
                        ? const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          )
                        : EdgeInsets.symmetric(
                            horizontal: layout.s4,
                            vertical: layout.s3,
                          ),
                    decoration: BoxDecoration(
                      color: colors.backgroundPrimary,
                      borderRadius: layout.radiusFull,
                      border: Border.all(
                        color: colors.backgroundModifierAccent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: widget.desktop ? -3 : 0,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                          spreadRadius: widget.desktop ? -4 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leading != null) ...[
                          leading,
                          SizedBox(width: layout.s3),
                        ] else if (widget.icon != null) ...[
                          PhosphorIcon(
                            widget.icon!,
                            size: 20,
                            color: widget.iconColor,
                          ),
                          SizedBox(width: layout.s3),
                        ],
                        Flexible(
                          child: Text(
                            message,
                            textAlign: centerMessage ? TextAlign.center : null,
                            style: textStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              height: widget.desktop ? 1.375 : null,
                            ),
                          ),
                        ),
                        if (action != null) ...[
                          SizedBox(width: layout.s3),
                          StarGestureDetector(
                            onTap: () => _runAction(action),
                            child: Text(
                              action.label,
                              style: textStyles.bodyMedium.copyWith(
                                color: colors.textLink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
