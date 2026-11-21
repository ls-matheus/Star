import 'package:star_app/features/channels/domain/channel.dart';
import 'package:star_app/features/channels/presentation/widgets/channel_notification_menu_content.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> showChannelNotificationSettingsSheet(
  BuildContext context, {
  required Channel channel,
}) async {
  final StarLocalizations l10n = StarLocalizations.of(context);
  await StarBottomSheet.show<void>(
    context,
    title: l10n.notificationSettings,
    variant: StarBottomSheetVariant.menu,
    builder: (sheetContext, close) =>
        ChannelNotificationMenuContent(channel: channel, onClose: close),
  );
}
