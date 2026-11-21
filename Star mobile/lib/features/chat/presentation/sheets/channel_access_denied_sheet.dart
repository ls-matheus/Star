import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showChannelAccessDeniedSheet(BuildContext context) {
  final l10n = StarLocalizations.of(context);
  return StarBottomSheet.show<void>(
    context,
    title: l10n.channelAccessDeniedTitle,
    builder: (sheetContext, close) {
      final layout = sheetContext.layout;
      final textStyles = sheetContext.textStyles;
      final colors = sheetContext.colors;
      return Padding(
        padding: EdgeInsets.fromLTRB(layout.s4, 0, layout.s4, 0),
        child: Text(
          l10n.channelAccessDeniedDescription,
          style: textStyles.bodySmall.copyWith(
            color: colors.textSecondary,
            height: 1.4,
          ),
        ),
      );
    },
  );
}
