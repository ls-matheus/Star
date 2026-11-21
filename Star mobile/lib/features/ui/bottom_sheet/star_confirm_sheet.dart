import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/star_haptics.dart';

class StarConfirmSheet {
  StarConfirmSheet._();

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    VoidCallback? onConfirm,
    String? description,
    Widget? body,
    bool isDanger = false,
    bool? useRootNavigator,
    String? cancelLabel,
  }) {
    return StarBottomSheet.show<bool>(
      context,
      useRootNavigator: useRootNavigator,
      title: title,
      builder: (sheetContext, close) {
        final textStyles = sheetContext.textStyles;
        final colors = sheetContext.colors;
        final layout = sheetContext.layout;

        final descriptionWidget = description == null
            ? null
            : Text(
                description,
                style: textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              );

        void confirm() {
          if (isDanger) {
            StarHaptics.warning();
          }
          onConfirm?.call();
          Navigator.of(sheetContext).pop(true);
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ?descriptionWidget,
                if (descriptionWidget != null && body != null)
                  SizedBox(height: layout.s4),
                ?body,
                SizedBox(height: layout.s4),
                if (isDanger)
                  StarButton.dangerPrimary(
                    onPressed: confirm,
                    label: confirmLabel,
                  )
                else
                  StarButton.primary(onPressed: confirm, label: confirmLabel),
                if (cancelLabel != null) ...[
                  SizedBox(height: layout.s2),
                  StarButton.secondary(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    label: cancelLabel,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
