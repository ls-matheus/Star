import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/list/star_list_row.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/material_ui.dart';

class StarListSection extends StatelessWidget {
  const StarListSection({
    required this.children,
    this.header,
    this.headerColor,
    this.dividers = true,
    this.backgroundColor,
    super.key,
  });

  final List<Widget> children;
  final String? header;
  final Color? headerColor;
  final Color? backgroundColor;

  final bool dividers;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dividerColor = colors.backgroundHeaderSecondary.withValues(
      alpha: 0.3,
    );

    final body = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      body.add(children[i]);
      if (dividers && i < children.length - 1) {
        body.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, thickness: 1, color: dividerColor),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null && header!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: context.layout.s3,
              bottom: context.layout.s1,
              left: context.layout.s4,
              right: context.layout.s4,
            ),
            child: Semantics(
              header: true,
              child: Text(
                header!,
                style: context.textStyles.categoryName.copyWith(
                  color: headerColor ?? colors.textPrimaryMuted,
                ),
              ),
            ),
          ),
        if (children.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    backgroundColor ?? StarBottomSheet.cardColorOf(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: body,
              ),
            ),
          ),
      ],
    );
  }
}

@StarWidgetPreview(name: 'With header', group: 'StarListSection')
Widget starListSectionPreview() {
  return StarListSection(
    header: 'Online — 2',
    children: [
      StarListRow(
        leading: const SizedBox.square(dimension: 40),
        title: 'Alice',
        onTap: () {},
      ),
      StarListRow(
        leading: const SizedBox.square(dimension: 40),
        title: 'Bob',
        onTap: () {},
      ),
    ],
  );
}
