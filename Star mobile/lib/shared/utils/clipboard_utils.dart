import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<void> copyToClipboard({
  required BuildContext context,
  required String value,
  String? message,
  StarToastVariant variant = StarToastVariant.success,
}) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) {
    return;
  }
  final String toastMessage =
      message ?? StarLocalizations.of(context).copiedToClipboard;
  ProviderScope.containerOf(context, listen: false)
      .read(toastProvider.notifier)
      .show(StarToast(message: toastMessage, variant: variant));
}
