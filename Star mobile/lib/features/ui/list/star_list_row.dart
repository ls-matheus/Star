import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';

class StarListRow extends StatelessWidget {
  const StarListRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.titleAdornments,
    this.tagsBelowTitle,
    this.dimmed = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final List<Widget>? titleAdornments;

  final List<Widget>? tagsBelowTitle;
  final bool dimmed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final hasSubtitleWidget = subtitleWidget != null;
    final hasSubtitle =
        hasSubtitleWidget || (subtitle != null && subtitle!.trim().isNotEmpty);
    final adornments = titleAdornments ?? const <Widget>[];
    final belowTags = tagsBelowTitle ?? const <Widget>[];

    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: context.textStyles.username.copyWith(
                              color: context.colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final adornment in adornments) ...[
                          const SizedBox(width: 6),
                          adornment,
                        ],
                      ],
                    ),
                    if (belowTags.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          for (var i = 0; i < belowTags.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            belowTags[i],
                          ],
                        ],
                      ),
                    ],
                    if (hasSubtitleWidget) ...[
                      const SizedBox(height: 2),
                      subtitleWidget!,
                    ] else if (hasSubtitle) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.textStyles.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );

    final Widget content = onTap != null || onLongPress != null
        ? Semantics(
            button: true,
            label: hasSubtitle ? '$title, $subtitle' : title,
            child: ExcludeSemantics(child: row),
          )
        : row;

    if (!dimmed) {
      return content;
    }
    return Opacity(opacity: 0.45, child: content);
  }
}

@StarWidgetPreview(name: 'Member row', group: 'StarListRow')
Widget starListRowPreview() {
  return StarListRow(
    leading: const StarAvatar(fallbackText: 'A', size: 40),
    title: 'Alice',
    subtitle: 'Working on something cool',
    onTap: () {},
  );
}

@StarWidgetPreview(name: 'Offline (dimmed)', group: 'StarListRow')
Widget starListRowDimmedPreview() {
  return StarListRow(
    leading: const StarAvatar(fallbackText: 'B', size: 40),
    title: 'Bob',
    dimmed: true,
    onTap: () {},
  );
}
