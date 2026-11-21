import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/material_ui.dart';

class StarSheetSectionItem {
  const StarSheetSectionItem({required this.id, required this.label});

  final String id;
  final String label;
}

class StarSheetSectionNav extends StatefulWidget {
  const StarSheetSectionNav({
    required this.sections,
    required this.activeSection,
    required this.onSectionTap,
    super.key,
  });

  final List<StarSheetSectionItem> sections;
  final String activeSection;
  final ValueChanged<String> onSectionTap;

  @override
  State<StarSheetSectionNav> createState() => _StarSheetSectionNavState();
}

class _StarSheetSectionNavState extends State<StarSheetSectionNav> {
  final Map<String, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didUpdateWidget(StarSheetSectionNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (oldWidget.activeSection != widget.activeSection) {
      _scrollToActive();
    }
  }

  void _syncKeys() {
    for (final section in widget.sections) {
      _keys.putIfAbsent(section.id, GlobalKey.new);
    }
    _keys.removeWhere((id, _) {
      return !widget.sections.any((s) => s.id == id);
    });
  }

  void _scrollToActive() {
    final key = _keys[widget.activeSection];
    if (key == null) {
      return;
    }
    final ctx = key.currentContext;
    if (ctx == null) {
      return;
    }
    final motion = context.motion;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: motion.normal,
      curve: motion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: layout.pageGutter),
        itemCount: widget.sections.length,
        separatorBuilder: (_, _) => SizedBox(width: layout.s2),
        itemBuilder: (context, index) {
          final section = widget.sections[index];
          final isActive = section.id == widget.activeSection;

          return _SheetSectionPill(
            key: _keys[section.id],
            section: section,
            isActive: isActive,
            onTap: () => widget.onSectionTap(section.id),
          );
        },
      ),
    );
  }
}

class _SheetSectionPill extends StatelessWidget {
  const _SheetSectionPill({
    required this.section,
    required this.isActive,
    required this.onTap,
    super.key,
  });

  final StarSheetSectionItem section;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final textStyles = context.textStyles;
    final motion = context.motion;

    return StarTappable(
      onTap: onTap,
      selected: isActive,
      semanticLabel: section.label,
      excludeChildSemantics: true,
      builder: (context, states) {
        return AnimatedContainer(
          duration: motion.fast,
          curve: motion.curve,
          padding: EdgeInsets.symmetric(
            horizontal: layout.s3,
            vertical: layout.s2,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? colors.brandPrimary
                : StarBottomSheet.cardColorOf(context),
            borderRadius: layout.radiusFull,
          ),
          child: AnimatedDefaultTextStyle(
            duration: motion.fast,
            curve: motion.curve,
            style: textStyles.bodySmall.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive
                  ? colors.textOnBrandPrimary
                  : colors.textSecondary,
            ),
            child: Text(section.label),
          ),
        );
      },
    );
  }
}

@StarWidgetPreview(name: 'Default', group: 'StarSheetSectionNav')
Widget starSheetSectionNavPreview() {
  return StarSheetSectionNav(
    sections: const [
      StarSheetSectionItem(id: 'general', label: 'General'),
      StarSheetSectionItem(id: 'privacy', label: 'Privacy'),
      StarSheetSectionItem(id: 'audio', label: 'Audio'),
    ],
    activeSection: 'privacy',
    onSectionTap: (_) {},
  );
}
