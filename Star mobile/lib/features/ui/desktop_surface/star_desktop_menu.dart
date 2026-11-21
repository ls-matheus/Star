part of 'star_desktop_surface.dart';

TextStyle starDesktopMenuLabelStyle(BuildContext context) => context
    .textStyles
    .label
    .copyWith(fontSize: 13, fontWeight: FontWeight.w500, height: 18 / 13);

Color starDesktopMenuDangerText(StarColorTheme colors) =>
    starCssColorMix(colors.statusDanger, colors.textPrimary, 0.78);

Color starDesktopMenuDangerBackground(StarColorTheme colors) =>
    starCssColorMix(
      colors.statusDanger,
      colors.surfaceInteractiveHoverBg,
      0.06,
    );

class StarDesktopMenuPanel extends StatelessWidget {
  const StarDesktopMenuPanel({
    required this.child,
    this.width = kStarDesktopMenuDefaultWidth,
    super.key,
  }) : fitContent = false;

  const StarDesktopMenuPanel.fitContent({required this.child, super.key})
    : width = null,
      fitContent = true;

  final Widget child;
  final double? width;
  final bool fitContent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final BorderRadius radius = BorderRadius.circular(8);

    final Widget panel = StarDesktopMenuContent(
      child: Container(
        width: width,
        constraints: fitContent
            ? const BoxConstraints(
                minWidth: kStarDesktopMenuMinWidth,
                maxWidth: kStarDesktopMenuMaxWidth,
              )
            : null,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: starDesktopPanelShadow(context),
        ),
        child: Material(
          color: starFormSurfaceBackground(context),
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: colors.backgroundModifierAccent),
          ),
          child: Padding(
            padding: const EdgeInsets.all(kStarDesktopMenuPadding),
            child: child,
          ),
        ),
      ),
    );
    return fitContent ? IntrinsicWidth(child: panel) : panel;
  }
}

class StarDesktopMenuContent extends StatelessWidget {
  const StarDesktopMenuContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StarDesktopSurfaceScope(
      surface: StarDesktopSurface.menu,
      child: ListTileTheme(
        data: ListTileThemeData(
          dense: true,
          minTileHeight: kStarDesktopMenuRowMinHeight,
          minVerticalPadding: 6,
          minLeadingWidth: kStarDesktopMenuIconSize,
          horizontalTitleGap: 8,
          contentPadding: const EdgeInsets.symmetric(horizontal: 9),
          iconColor: context.colors.textPrimary,
          textColor: context.colors.textPrimary,
          titleTextStyle: starDesktopMenuLabelStyle(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: child,
      ),
    );
  }
}

class StarDesktopPopoutPanel extends StatelessWidget {
  const StarDesktopPopoutPanel({
    required this.child,
    required this.width,
    this.showBorder = true,
    this.borderRadius = 8,
    super.key,
  });

  final Widget child;
  final double width;
  final bool showBorder;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final BorderRadius radius = BorderRadius.circular(borderRadius);
    return StarDesktopSurfaceScope(
      surface: StarDesktopSurface.popout,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: starDesktopPanelShadow(context),
        ),
        child: Material(
          color: colors.backgroundSecondary,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: showBorder
                ? BorderSide(color: colors.backgroundHeaderSecondary)
                : BorderSide.none,
          ),
          child: child,
        ),
      ),
    );
  }
}

class StarDesktopMenuRow extends StatelessWidget {
  const StarDesktopMenuRow({
    required this.label,
    required this.onTap,
    this.hint,
    this.leading,
    this.trailing,
    this.trailingBuilder,
    this.isDanger = false,
    this.enabled = true,
    this.selected = false,
    this.toggled,
    this.checked,
    this.labelColor,
    this.hintColor,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final String? hint;
  final Widget? leading;
  final Widget? trailing;
  final Widget Function(BuildContext context, {required bool highlighted})?
  trailingBuilder;
  final bool isDanger;
  final bool enabled;
  final bool selected;
  final bool? toggled;
  final bool? checked;
  final Color? labelColor;
  final Color? hintColor;
  final CrossAxisAlignment crossAxisAlignment;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color foreground =
        labelColor ??
        (!enabled
            ? colors.interactiveMuted
            : isDanger
            ? starDesktopMenuDangerText(colors)
            : colors.textPrimary);
    final Color hoverColor = isDanger
        ? starDesktopMenuDangerBackground(colors)
        : colors.surfaceInteractiveHoverBg;

    return StarTappable(
      enabled: enabled,
      onTap: onTap,
      selected: selected,
      toggled: toggled,
      checked: checked,
      semanticLabel: semanticLabel ?? (hint != null ? '$label. $hint' : label),
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) {
        final bool highlighted =
            enabled &&
            (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused));
        final Widget? trailingWidget =
            trailingBuilder?.call(context, highlighted: highlighted) ??
            trailing;

        return Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: kStarDesktopMenuRowMinHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: highlighted ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: foreground,
                  size: kStarDesktopMenuIconSize,
                ),
                child: Row(
                  crossAxisAlignment: crossAxisAlignment,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: starDesktopMenuLabelStyle(
                              context,
                            ).copyWith(color: foreground),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hint != null)
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: kStarDesktopMenuHintMaxWidth,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  hint!,
                                  style: starDesktopMenuLabelStyle(context)
                                      .copyWith(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        color:
                                            hintColor ??
                                            colors.textTertiaryMuted,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailingWidget != null) ...[
                      const SizedBox(width: 8),
                      trailingWidget,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StarDesktopMenuCheckbox extends StatelessWidget {
  const StarDesktopMenuCheckbox({
    required this.isChecked,
    this.dangerHighlighted = false,
    super.key,
  });

  final bool isChecked;
  final bool dangerHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Color fill = isChecked
        ? (dangerHighlighted ? colors.statusDanger : colors.brandPrimary)
        : starFormSurfaceBackground(context);
    final Color border = isChecked
        ? (dangerHighlighted ? colors.statusDanger : colors.brandPrimary)
        : dangerHighlighted
        ? starCssColorMix(colors.statusDanger, Colors.transparent, 0.46)
        : colors.backgroundModifierAccent;
    final Color check = dangerHighlighted
        ? Colors.white
        : colors.brandPrimaryFill;
    return SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: isChecked
              ? Center(
                  child: FractionalTranslation(
                    translation: const Offset(0, -0.1),
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Container(
                        width: 4,
                        height: 9,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: check, width: 2.5),
                            bottom: BorderSide(color: check, width: 2.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class StarDesktopMenuGroupLabel extends StatelessWidget {
  const StarDesktopMenuGroupLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.label.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 16 / 11,
          letterSpacing: 0.22,
          color: context.colors.textTertiary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class StarDesktopMenuSeparator extends StatelessWidget {
  const StarDesktopMenuSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      color: context.colors.backgroundModifierAccent.withValues(
        alpha: context.colors.backgroundModifierAccent.a * 0.55,
      ),
    );
  }
}
