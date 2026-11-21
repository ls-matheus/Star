import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/material_ui.dart';

class UserProfileConfirmationSheet {
  UserProfileConfirmationSheet._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    required String primaryLabel,
    required StarButtonVariant primaryVariant,
  }) async {
    final result = await StarBottomSheet.show<bool>(
      context,
      title: title,
      useRootNavigator: true,
      builder: (sheetContext, close) {
        final colors = sheetContext.colors;
        final layout = sheetContext.layout;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                description,
                style: sheetContext.textStyles.bodySmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: layout.s4),
              _buildPrimaryButton(
                variant: primaryVariant,
                label: primaryLabel,
                onPressed: () =>
                    Navigator.of(sheetContext, rootNavigator: true).pop(true),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  static Widget _buildPrimaryButton({
    required StarButtonVariant variant,
    required String label,
    required VoidCallback onPressed,
  }) {
    return switch (variant) {
      StarButtonVariant.primary => StarButton.primary(
        label: label,
        onPressed: onPressed,
      ),
      StarButtonVariant.secondary => StarButton.secondary(
        label: label,
        onPressed: onPressed,
      ),
      StarButtonVariant.dangerPrimary => StarButton.dangerPrimary(
        label: label,
        onPressed: onPressed,
      ),
      StarButtonVariant.dangerSecondary => StarButton.dangerSecondary(
        label: label,
        onPressed: onPressed,
      ),
      StarButtonVariant.inverted => StarButton.inverted(
        label: label,
        onPressed: onPressed,
      ),
      StarButtonVariant.invertedOutline => StarButton.invertedOutline(
        label: label,
        onPressed: onPressed,
      ),
      StarButtonVariant.ghost => StarButton.ghost(
        label: label,
        onPressed: onPressed,
      ),
    };
  }
}
