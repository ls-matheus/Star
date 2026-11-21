import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/features/ui/preview/star_widget_preview.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class StarSaveBar extends StatelessWidget {
  const StarSaveBar({
    required this.visible,
    required this.onReset,
    required this.onSave,
    this.isSaving = false,
    this.label,
    super.key,
  });

  final bool visible;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final bool isSaving;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final motion = context.motion;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final StarLocalizations l10n = StarLocalizations.of(context);

    return ExcludeSemantics(
      excluding: !visible,
      child: AnimatedSlide(
        duration: motion.normal,
        curve: motion.curve,
        offset: visible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: motion.normal,
          curve: motion.curve,
          opacity: visible ? 1.0 : 0.0,
          child: DecoratedBox(
            key: ValueKey<bool>(visible),
            decoration: BoxDecoration(
              color: colors.backgroundSecondaryAlt,
              border: Border(top: BorderSide(color: colors.borderColor)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: layout.s4,
                right: layout.s4,
                top: layout.s3,
                bottom: bottomPadding > 0 ? bottomPadding : layout.s3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label ?? l10n.uiUnsavedChanges,
                      style: context.textStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: layout.s2),
                  StarButton.secondary(
                    onPressed: isSaving ? null : onReset,
                    label: l10n.uiReset,
                    size: StarButtonSize.small,
                    fitContent: true,
                  ),
                  SizedBox(width: layout.s2),
                  StarButton.primary(
                    onPressed: isSaving ? null : onSave,
                    label: l10n.save,
                    size: StarButtonSize.small,
                    isLoading: isSaving,
                    fitContent: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@StarWidgetPreview(name: 'Visible', group: 'StarSaveBar')
Widget starSaveBarVisiblePreview() {
  return StarSaveBar(visible: true, onReset: () {}, onSave: () {});
}

@StarWidgetPreview(name: 'Hidden', group: 'StarSaveBar')
Widget starSaveBarHiddenPreview() {
  return StarSaveBar(visible: false, onReset: () {}, onSave: () {});
}
