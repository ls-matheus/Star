import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class ChannelFollowSuccessSheet {
  ChannelFollowSuccessSheet._();

  static Future<void> show(
    BuildContext context, {
    required String sourceName,
    required String targetName,
  }) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarModal.show<void>(
      context,
      title: l10n.channelFollowSuccessTitle,
      centered: true,
      builder: (BuildContext dialogContext, VoidCallback close) {
        return Text(
          l10n.channelFollowSuccessBody(sourceName, targetName),
          style: dialogContext.textStyles.bodySmall.copyWith(height: 1.4),
        );
      },
      actionsBuilder: (void Function([void]) pop) => <Widget>[
        StarButton.primary(
          onPressed: () => pop(),
          label: l10n.channelFollowSuccessDismiss,
        ),
      ],
    );
  }
}
