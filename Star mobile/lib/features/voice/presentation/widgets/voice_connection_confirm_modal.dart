import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

enum VoiceConnectionConfirmResult { switchToThisDevice, justJoin }

Future<VoiceConnectionConfirmResult?> showVoiceConnectionConfirmModal(
  BuildContext context, {
  required int otherDeviceCount,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  final String description = l10n.voiceConnectionConfirmDescription(
    otherDeviceCount,
  );

  List<Widget> buildActions(
    void Function([VoiceConnectionConfirmResult? result]) pop,
  ) {
    return <Widget>[
      StarButton.primary(
        onPressed: () => pop(VoiceConnectionConfirmResult.switchToThisDevice),
        label: l10n.voiceConnectionConfirmSwitch,
      ),
      const SizedBox(height: 8),
      StarButton.secondary(
        onPressed: () => pop(VoiceConnectionConfirmResult.justJoin),
        label: l10n.voiceConnectionConfirmJustJoin,
      ),
      const SizedBox(height: 8),
      StarButton.secondary(
        onPressed: () => pop(),
        label: l10n.voiceConnectionConfirmDoNothing,
      ),
    ];
  }

  if (isMobileLayout(context)) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    return StarBottomSheet.show<VoiceConnectionConfirmResult?>(
      context,
      useRootNavigator: true,
      title: l10n.voiceConnectionConfirmTitle,
      subtitle: Text(
        description,
        style: textStyles.bodySmall.copyWith(
          color: colors.textSecondary,
          height: 1.4,
        ),
      ),
      trailing: Opacity(
        opacity: 0.7,
        child: StarButton.ghost(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          icon: PhosphorIconsBold.x,
          isSquare: true,
          semanticLabel: l10n.uiClose,
        ),
      ),
      builder: (BuildContext sheetContext, VoidCallback close) {
        void pop([VoiceConnectionConfirmResult? result]) {
          Navigator.of(sheetContext).pop(result);
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: sheetContext.layout.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildActions(pop),
          ),
        );
      },
    );
  }

  return StarModal.show<VoiceConnectionConfirmResult?>(
    context,
    useRootNavigator: true,
    centered: true,
    title: l10n.voiceConnectionConfirmTitle,
    description: description,
    builder: (BuildContext dialogContext, VoidCallback close) {
      return const SizedBox.shrink();
    },
    actionsBuilder: buildActions,
  );
}
