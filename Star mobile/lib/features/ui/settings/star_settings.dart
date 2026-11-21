import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class StarSettingsHeader extends StatelessWidget {
  const StarSettingsHeader({
    required this.title,
    super.key,
    this.description,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? description;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final StarLocalizations l10n = StarLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  tooltip: l10n.back,
                  icon: PhosphorIcon(
                    PhosphorIconsBold.caretLeft,
                    size: 20,
                    color: colors.textPrimary,
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  style: context.textStyles.heading.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
          if (description != null) ...[
            SizedBox(height: layout.s1),
            Text(
              description!,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StarSettingsFormSection extends StatelessWidget {
  const StarSettingsFormSection({
    required this.children,
    super.key,
    this.title,
    this.description,
  });

  final String? title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return Padding(
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: context.textStyles.heading.copyWith(
                color: colors.textPrimary,
              ),
            ),
            if (description != null) ...[
              SizedBox(height: layout.s1),
              Text(
                description!,
                style: context.textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            SizedBox(height: layout.s3),
          ],
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: layout.s3),
          ],
        ],
      ),
    );
  }
}

class StarSettingsDangerZone extends StatelessWidget {
  const StarSettingsDangerZone({
    required this.child,
    super.key,
    this.title,
    this.description,
  });

  final String? title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return Padding(
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Text(
              title!,
              style: context.textStyles.label.copyWith(
                color: colors.statusDanger,
              ),
            ),
          if (description != null) ...[
            SizedBox(height: layout.s1),
            Text(
              description!,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: layout.s3),
          child,
        ],
      ),
    );
  }
}

@StarWidgetPreview(name: 'Header', group: 'StarSettings')
Widget starSettingsHeaderPreview() {
  return const StarSettingsHeader(
    title: 'Notifications',
    description: 'Choose what you get notified about.',
  );
}

@StarWidgetPreview(name: 'Form section', group: 'StarSettings')
Widget starSettingsFormSectionPreview() {
  return const StarSettingsFormSection(
    title: 'Profile',
    description: 'This information is visible to others.',
    children: [StarInput(label: 'Display name', hint: 'Your name')],
  );
}

@StarWidgetPreview(name: 'Danger zone', group: 'StarSettings')
Widget starSettingsDangerZonePreview() {
  return StarSettingsDangerZone(
    title: 'Danger zone',
    description: 'These actions are permanent.',
    child: StarButton.dangerSecondary(
      onPressed: () {},
      label: 'Delete account',
    ),
  );
}
