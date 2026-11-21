import 'package:star_app/core/platform/star_platform.dart';
import 'package:star_app/core/theme/star_color_theme.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/animation/animation_controller_visibility_extension.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/button/star_button_variant.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/spinner/star_loading_spinner.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/features/ui/tooltip/star_tooltip.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

part 'star_button_desktop.dart';

class StarButton extends StatefulWidget {
  const StarButton.primary({
    this.onPressed,
    this.onPressedAsync,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = StarButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.recording = false,
    this.child,
    this.semanticLabel,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.primary,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.secondary({
    this.onPressed,
    this.onPressedAsync,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = StarButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.recording = false,
    this.child,
    this.semanticLabel,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.secondary,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.dangerPrimary({
    this.onPressed,
    this.onPressedAsync,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = StarButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.recording = false,
    this.child,
    this.semanticLabel,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.dangerPrimary,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.dangerSecondary({
    this.onPressed,
    this.onPressedAsync,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = StarButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.recording = false,
    this.child,
    this.semanticLabel,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.dangerSecondary,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.inverted({
    this.onPressed,
    this.onPressedAsync,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = StarButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.recording = false,
    this.child,
    this.semanticLabel,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.inverted,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.invertedOutline({
    this.onPressed,
    this.onPressedAsync,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = StarButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.recording = false,
    this.child,
    this.semanticLabel,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.invertedOutline,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.ghost({
    this.onPressed,
    this.onPressedAsync,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = StarButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.recording = false,
    this.child,
    this.semanticLabel,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.ghost,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.mediaOverlay({
    this.onPressed,
    this.onPressedAsync,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = StarButtonSize.regular,
    this.isSquare = false,
    this.isLoading = false,
    this.fitContent = false,
    this.recording = false,
    this.child,
    this.semanticLabel,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.secondary,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = true,
       _iconSizeOverride = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.circle({
    required IconData this.icon,
    required String this.semanticLabel,
    this.onPressed,
    this.onPressedAsync,
    this._variant = StarButtonVariant.primary,
    this.size = StarButtonSize.regular,
    double? iconSize,
    this.isLoading = false,
    this.recording = false,
    super.key,
  }) : _desktopIcon = null,
       _isCircle = true,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = iconSize,
       isSquare = true,
       label = null,
       trailingIcon = null,
       fitContent = false,
       child = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  const StarButton.circleAlt({
    required IconData this.icon,
    required String this.semanticLabel,
    this.onPressed,
    this.onPressedAsync,
    this.size = StarButtonSize.small,
    double? iconSize = 20,
    this.isLoading = false,
    this.recording = false,
    super.key,
  }) : _desktopIcon = null,
       _variant = StarButtonVariant.secondary,
       _isCircle = true,
       _isCircleAltStyle = true,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = iconSize,
       isSquare = true,
       label = null,
       trailingIcon = null,
       fitContent = false,
       child = null,
       assert(
         onPressed == null || onPressedAsync == null,
         'Cannot provide both onPressed and onPressedAsync',
       );

  StarButton.desktop({
    required IconData this.icon,
    required String this.semanticLabel,
    required this.onPressed,
    bool showTooltip = false,
    double extent = 24,
    double iconSize = 16,
    double borderRadius = 4,
    bool circle = false,
    bool active = false,
    Color? color,
    Color? hoverColor,
    Color? background,
    Color? hoverBackground,
    Color? border,
    Color? hoverBorder,
    List<BoxShadow>? shadows,
    Duration? duration,
    super.key,
  }) : _desktopIcon = _StarDesktopIconStyle(
         showTooltip: showTooltip,
         extent: extent,
         borderRadius: borderRadius,
         circle: circle,
         active: active,
         color: color,
         hoverColor: hoverColor,
         background: background,
         hoverBackground: hoverBackground,
         border: border,
         hoverBorder: hoverBorder,
         shadows: shadows,
         duration: duration,
       ),
       _variant = StarButtonVariant.ghost,
       _isCircle = false,
       _isCircleAltStyle = false,
       _isMediaOverlayStyle = false,
       _iconSizeOverride = iconSize,
       onPressedAsync = null,
       size = StarButtonSize.regular,
       isSquare = true,
       isLoading = false,
       recording = false,
       label = null,
       trailingIcon = null,
       fitContent = false,
       child = null;

  final _StarDesktopIconStyle? _desktopIcon;
  final StarButtonVariant _variant;
  final bool _isCircle;
  final bool _isCircleAltStyle;
  final bool _isMediaOverlayStyle;
  final double? _iconSizeOverride;
  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final StarButtonSize size;
  final bool isSquare;
  final bool isLoading;
  final bool fitContent;
  final bool recording;
  final Widget? child;
  final String? semanticLabel;

  @override
  State<StarButton> createState() => _StarButtonState();
}

class _StarButtonState extends State<StarButton> {
  bool _asyncLoading = false;

  bool get _effectiveLoading => widget.isLoading || _asyncLoading;
  bool get _enabled =>
      (widget.onPressed != null || widget.onPressedAsync != null) &&
      !_effectiveLoading;

  BorderRadius get _borderRadius {
    if (!widget._isCircle && widget._isMediaOverlayStyle) {
      return BorderRadius.circular(10);
    }
    return BorderRadius.circular(
      widget._isCircle
          ? widget.size.height / 2
          : switch (widget.size) {
              StarButtonSize.regular || StarButtonSize.small => 8.0,
              StarButtonSize.compact || StarButtonSize.superCompact => 6.0,
            },
    );
  }

  void _handleTap() {
    if (widget.onPressedAsync != null) {
      setState(() => _asyncLoading = true);
      widget.onPressedAsync!().whenComplete(() {
        if (mounted) {
          setState(() => _asyncLoading = false);
        }
      }).ignore();
    } else {
      widget.onPressed?.call();
    }
  }

  String? _resolveSemanticsLabel(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String? base = widget.semanticLabel ?? widget.label;
    if (!_effectiveLoading) {
      return base;
    }
    if (base == null) {
      return l10n.uiLoading;
    }
    return '$base, ${l10n.uiLoading}';
  }

  bool get _usesDesktopStyle =>
      !widget._isCircle && !widget._isMediaOverlayStyle;

  @override
  Widget build(BuildContext context) {
    final _StarDesktopIconStyle? desktopIcon = widget._desktopIcon;
    if (desktopIcon != null) {
      return _buildStarDesktopIconButton(context, widget, desktopIcon);
    }
    if (_usesDesktopStyle && usesDesktopPointerUi(context)) {
      return _buildDesktop(context);
    }
    final colors = context.colors;
    final motion = context.motion;
    final foreground = widget.recording
        ? colors.brandPrimaryFill
        : _resolveTextColor(colors);

    return StarTappable(
      onTap: _enabled ? _handleTap : null,
      enabled: _enabled,
      semanticLabel: _resolveSemanticsLabel(context),
      excludeChildSemantics: true,
      builder: (context, states) {
        final isHovered = states.contains(WidgetState.hovered);
        final fill = widget.recording
            ? colors.accentSuccess
            : isHovered
            ? _resolveActiveFill(colors)
            : _resolveFill(colors);
        final border = widget.recording
            ? null
            : _resolveBorderColor(colors, hovered: isHovered);

        Widget container = AnimatedContainer(
          duration: motion.fast,
          curve: motion.curve,
          constraints: BoxConstraints(
            minHeight: widget.size.height,
            minWidth: widget.isSquare
                ? widget.size.height
                : (widget.fitContent ? 0 : 96),
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: _borderRadius,
            border: border != null ? Border.all(color: border) : null,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSquare ? 0 : widget.size.padding,
          ),
          child: _buildContent(foreground),
        );

        if (widget.recording) {
          container = _RecordingPulse(
            color: colors.accentSuccess,
            borderRadius: _borderRadius,
            child: container,
          );
        }

        return container;
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final colors = context.colors;
    final _DesktopButtonMetrics metrics = _DesktopButtonMetrics.of(widget.size);
    final BorderRadius radius = BorderRadius.circular(metrics.radius);
    final _DesktopButtonColors palette = _DesktopButtonColors.resolve(
      context,
      widget._variant,
    );
    final Color foreground = widget.recording
        ? colors.buttonPrimaryText
        : palette.text;

    return StarTappable(
      onTap: _enabled ? _handleTap : null,
      enabled: _enabled,
      semanticLabel: _resolveSemanticsLabel(context),
      excludeChildSemantics: true,
      builder: (context, states) {
        final bool active = _enabled && states.contains(WidgetState.pressed);
        final bool hovered = _enabled && states.contains(WidgetState.hovered);
        final Color fill;
        final Color border;
        if (widget.recording) {
          fill = colors.accentSuccess;
          border = starCssColorMix(colors.accentSuccess, Colors.white, 0.8);
        } else if (active) {
          fill = palette.activeFill ?? palette.hoverFill ?? palette.fill;
          border = palette.hoverBorder ?? palette.border;
        } else if (hovered) {
          fill = palette.hoverFill ?? palette.fill;
          border = palette.hoverBorder ?? palette.border;
        } else {
          fill = palette.fill;
          border = palette.border;
        }

        final double minWidth = widget.isSquare
            ? metrics.height
            : (widget.fitContent ? 0 : metrics.minWidth);
        Widget container = AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.ease,
          constraints: BoxConstraints(
            minHeight: metrics.height,
            maxHeight: metrics.height,
            minWidth: minWidth,
            maxWidth: widget.isSquare ? metrics.height : double.infinity,
          ),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: border),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSquare ? 0 : metrics.horizontalPadding,
          ),
          child: _buildDesktopContent(context, foreground, metrics),
        );

        if (widget.recording) {
          container = _RecordingPulse(
            color: colors.accentSuccess,
            borderRadius: radius,
            child: container,
          );
        }

        return container;
      },
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    Color foreground,
    _DesktopButtonMetrics metrics,
  ) {
    final double iconSize = widget._iconSizeOverride ?? metrics.iconSize;
    final TextStyle labelStyle = context.textStyles.categoryName.copyWith(
      fontSize: metrics.fontSize,
      fontWeight: FontWeight.w600,
      height: metrics.lineHeight / metrics.fontSize,
      color: foreground,
    );
    final contentWidgets = <Widget>[
      if (widget.icon != null)
        PhosphorIcon(widget.icon!, size: iconSize, color: foreground),
      if (widget.child != null)
        Flexible(
          child: DefaultTextStyle.merge(
            style: labelStyle,
            child: widget.child!,
          ),
        )
      else if (widget.label != null)
        Flexible(
          child: Text(
            widget.label!,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      if (widget.trailingIcon != null)
        PhosphorIcon(
          widget.trailingIcon!,
          size: metrics.iconSize,
          color: foreground,
        ),
    ];

    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 6,
      children: contentWidgets,
    );
    if (!_effectiveLoading) {
      return row;
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0, child: row),
        ExcludeSemantics(
          child: StarPulsingEllipsis(color: foreground, dotSize: 5),
        ),
      ],
    );
  }

  Color _resolveFill(StarColorTheme colors) {
    if (widget._isCircleAltStyle) {
      return colors.backgroundTertiary;
    }
    if (widget._isMediaOverlayStyle) {
      return colors.backgroundTextarea;
    }
    return widget._variant.fill(colors);
  }

  Color _resolveActiveFill(StarColorTheme colors) {
    if (widget._isCircleAltStyle || widget._isMediaOverlayStyle) {
      return colors.backgroundSecondaryAlt;
    }
    return widget._variant.activeFill(colors);
  }

  Color _resolveTextColor(StarColorTheme colors) {
    if (widget._isCircleAltStyle || widget._isMediaOverlayStyle) {
      return colors.textPrimary;
    }
    return widget._variant.textColor(colors);
  }

  Color? _resolveBorderColor(StarColorTheme colors, {required bool hovered}) {
    if (widget._isMediaOverlayStyle) {
      return isStarMobileOs ? null : colors.backgroundModifierAccent;
    }
    return widget._variant.borderColor(colors, hovered: hovered);
  }

  Widget _buildContent(Color foreground) {
    final effectiveIconSize = widget._iconSizeOverride ?? widget.size.iconSize;

    if (_effectiveLoading) {
      return Center(
        child: ExcludeSemantics(
          child: StarLoadingSpinner(
            color: foreground,
            size: StarLoadingSpinnerSize.small,
          ),
        ),
      );
    }

    final contentWidgets = <Widget>[];

    if (widget.icon != null) {
      contentWidgets.add(
        PhosphorIcon(widget.icon!, size: effectiveIconSize, color: foreground),
      );
    }

    if (widget.child != null) {
      contentWidgets.add(Flexible(child: widget.child!));
    } else if (widget.label != null) {
      contentWidgets.add(
        Flexible(
          child: Text(
            widget.label!,
            style: context.textStyles.categoryName.copyWith(
              fontSize: widget.size.fontSize,
              color: foreground,
              height: 1.4,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }

    if (widget.trailingIcon != null) {
      contentWidgets.add(
        PhosphorIcon(
          widget.trailingIcon!,
          size: widget.size.iconSize,
          color: foreground,
        ),
      );
    }

    return Row(
      mainAxisSize: widget.fitContent || widget.isSquare
          ? MainAxisSize.min
          : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: _addSpacing(contentWidgets),
    );
  }

  List<Widget> _addSpacing(List<Widget> widgets) {
    if (widgets.length <= 1) {
      return widgets;
    }
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i < widgets.length - 1) {
        result.add(const SizedBox(width: 8));
      }
    }
    return result;
  }
}

class _DesktopButtonMetrics {
  const _DesktopButtonMetrics({
    required this.height,
    required this.minWidth,
    required this.horizontalPadding,
    required this.fontSize,
    required this.lineHeight,
    required this.iconSize,
    required this.radius,
  });

  factory _DesktopButtonMetrics.of(StarButtonSize size) => switch (size) {
    StarButtonSize.regular => const _DesktopButtonMetrics(
      height: 36,
      minWidth: 72,
      horizontalPadding: 12,
      fontSize: 13,
      lineHeight: 18,
      iconSize: 16,
      radius: 8,
    ),
    StarButtonSize.small => const _DesktopButtonMetrics(
      height: 34,
      minWidth: 56,
      horizontalPadding: 10,
      fontSize: 13,
      lineHeight: 18,
      iconSize: 16,
      radius: 8,
    ),
    StarButtonSize.compact => const _DesktopButtonMetrics(
      height: 32,
      minWidth: 52,
      horizontalPadding: 10,
      fontSize: 13,
      lineHeight: 18,
      iconSize: 16,
      radius: 8,
    ),
    StarButtonSize.superCompact => const _DesktopButtonMetrics(
      height: 26,
      minWidth: 0,
      horizontalPadding: 7,
      fontSize: 12,
      lineHeight: 16,
      iconSize: 14,
      radius: 6,
    ),
  };

  final double height;
  final double minWidth;
  final double horizontalPadding;
  final double fontSize;
  final double lineHeight;
  final double iconSize;
  final double radius;
}

class _DesktopButtonColors {
  const _DesktopButtonColors({
    required this.fill,
    required this.border,
    required this.text,
    this.hoverFill,
    this.hoverBorder,
    this.activeFill,
  });

  factory _DesktopButtonColors.resolve(
    BuildContext context,
    StarButtonVariant variant,
  ) {
    final colors = context.colors;
    final bool isLight = Theme.of(context).brightness == Brightness.light;
    switch (variant) {
      case StarButtonVariant.primary:
        return _DesktopButtonColors(
          fill: colors.brandPrimary,
          border: starCssColorMix(colors.brandPrimary, Colors.white, 0.82),
          text: colors.brandPrimaryFill,
          hoverFill: colors.brandSecondary,
          hoverBorder: starCssColorMix(
            colors.brandSecondary,
            Colors.white,
            0.84,
          ),
          activeFill: starCssColorMix(colors.brandPrimary, Colors.black, 0.9),
        );
      case StarButtonVariant.secondary:
        final Color surface = starFormSurfaceBackground(context);
        return _DesktopButtonColors(
          fill: surface,
          border: colors.backgroundModifierAccent,
          text: isLight ? colors.buttonGhostText : colors.buttonSecondaryText,
          hoverFill: starCssColorMix(surface, colors.textPrimary, 0.94),
          hoverBorder: starCssColorMix(
            colors.backgroundModifierAccent,
            colors.textTertiary,
            0.88,
          ),
        );
      case StarButtonVariant.dangerPrimary:
        return _DesktopButtonColors(
          fill: starCssColorMix(
            colors.buttonDangerFill,
            colors.backgroundPrimary,
            0.92,
          ),
          border: starCssColorMix(
            colors.buttonDangerFill,
            Colors.transparent,
            0.7,
          ),
          text: colors.buttonDangerText,
          hoverFill: starCssColorMix(
            colors.buttonDangerActiveFill,
            colors.backgroundPrimary,
            0.92,
          ),
          hoverBorder: starCssColorMix(
            colors.buttonDangerActiveFill,
            Colors.transparent,
            0.72,
          ),
          activeFill: starCssColorMix(
            colors.buttonDangerActiveFill,
            Colors.black,
            0.78,
          ),
        );
      case StarButtonVariant.dangerSecondary:
        final Color surface = starFormSurfaceBackground(context);
        return _DesktopButtonColors(
          fill: surface,
          border: colors.backgroundModifierAccent,
          text: colors.buttonDangerOutlineText,
          hoverFill: colors.buttonDangerOutlineActiveFill,
          hoverBorder: starCssColorMix(
            colors.backgroundModifierAccent,
            colors.textTertiary,
            0.88,
          ),
        );
      case StarButtonVariant.inverted:
        return _DesktopButtonColors(
          fill: colors.buttonInvertedFill,
          border: Colors.transparent,
          text: colors.buttonInvertedText,
        );
      case StarButtonVariant.invertedOutline:
        return _DesktopButtonColors(
          fill: Colors.transparent,
          border: Colors.white.withValues(alpha: 0.78),
          text: Colors.white,
          hoverFill: Colors.white.withValues(alpha: 0.1),
          activeFill: Colors.white.withValues(alpha: 0.05),
        );
      case StarButtonVariant.ghost:
        final Color text = colors.buttonGhostText;
        return _DesktopButtonColors(
          fill: Colors.transparent,
          border: Colors.transparent,
          text: text,
          hoverFill: text.withValues(alpha: text.a * 0.12),
          activeFill: text.withValues(alpha: text.a * 0.06),
        );
    }
  }

  final Color fill;
  final Color border;
  final Color text;
  final Color? hoverFill;
  final Color? hoverBorder;
  final Color? activeFill;
}

class _RecordingPulse extends StatefulWidget {
  const _RecordingPulse({
    required this.color,
    required this.borderRadius,
    required this.child,
  });

  final Color color;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<_RecordingPulse> createState() => _RecordingPulseState();
}

class _RecordingPulseState extends State<_RecordingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.syncWithVisibility(
      isVisible: true,
      animationsEnabled: !MediaQuery.disableAnimationsOf(context),
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final pulse = t <= 0.5 ? t / 0.5 : (1.0 - t) / 0.5;

        final spread1Opacity = 0.18 + 0.10 * pulse;
        final spread2Opacity = 0.12 * pulse;
        final spread2Radius = 6.0 * pulse;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(color: widget.color.withValues(alpha: spread1Opacity)),
              BoxShadow(
                color: widget.color.withValues(alpha: spread2Opacity),
                spreadRadius: spread2Radius,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

@StarWidgetPreview(name: 'Primary', group: 'StarButton')
Widget starButtonPrimaryPreview() {
  return StarButton.primary(onPressed: () {}, label: 'Continue');
}

@StarWidgetPreview(name: 'Secondary', group: 'StarButton')
Widget starButtonSecondaryPreview() {
  return StarButton.secondary(onPressed: () {}, label: 'Cancel');
}

@StarWidgetPreview(name: 'Danger secondary', group: 'StarButton')
Widget starButtonDangerSecondaryPreview() {
  return StarButton.dangerSecondary(
    onPressed: () {},
    label: 'Delete channel',
  );
}

@StarWidgetPreview(name: 'Ghost', group: 'StarButton')
Widget starButtonGhostPreview() {
  return StarButton.ghost(onPressed: () {}, label: 'Learn more');
}

@StarWidgetPreview(name: 'Media overlay', group: 'StarButton')
Widget starButtonMediaOverlayPreview() {
  return ColoredBox(
    color: Colors.black.withValues(alpha: 0.55),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: StarButton.mediaOverlay(
        onPressed: () {},
        icon: PhosphorIconsBold.x,
        isSquare: true,
        semanticLabel: 'Close',
      ),
    ),
  );
}

@StarWidgetPreview(name: 'Circle icon', group: 'StarButton')
Widget starButtonCirclePreview() {
  return StarButton.circle(
    onPressed: () {},
    icon: PhosphorIconsBold.plus,
    semanticLabel: 'Add',
  );
}

@StarWidgetPreview(name: 'Circle alt', group: 'StarButton')
Widget starButtonCircleAltPreview() {
  return StarButton.circleAlt(
    onPressed: () {},
    icon: PhosphorIconsBold.gear,
    semanticLabel: 'Settings',
  );
}
