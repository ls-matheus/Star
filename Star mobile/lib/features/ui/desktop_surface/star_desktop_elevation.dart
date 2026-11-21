part of 'star_desktop_surface.dart';

List<BoxShadow> starDesktopPanelShadow(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.14),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

const List<BoxShadow> kStarDesktopCardHoverShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 4),
    blurRadius: 6,
    spreadRadius: -1,
  ),
  BoxShadow(
    color: Color(0x0F000000),
    offset: Offset(0, 2),
    blurRadius: 4,
    spreadRadius: -1,
  ),
];

Color starFormSurfaceBackground(BuildContext context) {
  final colors = context.colors;
  return Theme.of(context).brightness == Brightness.dark
      ? colors.backgroundTertiary
      : colors.backgroundPrimary;
}

Color starDesktopHoverOver(BuildContext context, Color surface) =>
    Color.alphaBlend(context.colors.backgroundModifierHover, surface);

BoxDecoration starDesktopFloatingDecoration(
  BuildContext context, {
  double radius = 8,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    color: starFormSurfaceBackground(context),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: context.colors.backgroundModifierAccent),
    boxShadow: shadows ?? starDesktopPanelShadow(context),
  );
}

TextStyle starDesktopRowTitleStyle(BuildContext context) => context
    .textStyles
    .label
    .copyWith(fontSize: 16, fontWeight: FontWeight.w500, height: 20 / 16);

TextStyle starDesktopRowSubtextStyle(BuildContext context) =>
    context.textStyles.timestamp.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 16 / 11,
      color: starDesktopSubtleText(context.colors),
    );

TextStyle starDesktopEyebrowStyle(BuildContext context) =>
    context.textStyles.smallText.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 16 / 11,
      letterSpacing: 0,
    );

TextStyle starDesktopDescriptionStyle(BuildContext context) => context
    .textStyles
    .bodySmall
    .copyWith(fontSize: 13, height: 1.4, color: context.colors.textSecondary);

Color starDesktopSubtleText(StarColorTheme colors) =>
    starCssColorMix(colors.textPrimaryMuted, const Color(0x00000000), 0.85);
