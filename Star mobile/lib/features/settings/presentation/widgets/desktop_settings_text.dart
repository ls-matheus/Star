import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/desktop_surface/star_desktop_surface.dart';
import 'package:star_app/material_ui.dart';

TextStyle desktopSettingsTitleStyle(BuildContext context) =>
    context.textStyles.heading.copyWith(
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      color: context.colors.textPrimary,
    );

TextStyle desktopSettingsSubtitleStyle(BuildContext context) =>
    context.textStyles.bodySmall.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      color: context.colors.textPrimaryMuted,
    );

class DesktopSettingsPageTitle extends StatelessWidget {
  const DesktopSettingsPageTitle({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(title, style: desktopSettingsTitleStyle(context)),
        const SizedBox(height: 8),
        Text(description, style: desktopSettingsSubtitleStyle(context)),
      ],
    );
  }
}

class DesktopSettingsSidebarTitle extends StatelessWidget {
  const DesktopSettingsSidebarTitle(
    this.label, {
    this.large = false,
    super.key,
  });

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final double fontSize = large ? 12 : 11;
    return Padding(
      padding: large
          ? const EdgeInsets.fromLTRB(8, 6, 8, 10)
          : const EdgeInsets.fromLTRB(10, 4, 10, 7),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: starDesktopEyebrowStyle(context).copyWith(
          fontSize: fontSize,
          height: (large ? 18 : 16) / fontSize,
          letterSpacing: fontSize * 0.02,
          color: context.colors.textTertiary,
        ),
      ),
    );
  }
}
