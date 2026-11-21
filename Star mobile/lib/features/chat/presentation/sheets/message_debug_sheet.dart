import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/widgets/debug_bottom_sheet.dart';

Future<void> showMessageDebugSheet(
  BuildContext context, {
  required Message message,
}) {
  final StarLocalizations l10n = StarLocalizations.of(context);
  return showDebugBottomSheet(
    context,
    title: l10n.chatMessageDebugSheetTitle,
    data: message.toJson(),
    copiedMessage: l10n.chatMessageDebugJsonCopiedToast,
  );
}
