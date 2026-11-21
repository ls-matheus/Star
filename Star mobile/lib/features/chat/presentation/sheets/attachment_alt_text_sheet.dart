import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/providers/core/chat_view_model.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<String?> showAttachmentAltTextSheet(
  BuildContext context, {
  required Attachment attachment,
  bool useRootNavigator = true,
}) {
  return StarBottomSheet.show<String?>(
    context,
    useRootNavigator: useRootNavigator,
    title: StarLocalizations.of(context).chatAttachmentEditTitle,
    builder: (BuildContext sheetContext, VoidCallback close) {
      return _AttachmentAltTextSheetBody(
        attachment: attachment,
        onClose: close,
        useRootNavigator: useRootNavigator,
      );
    },
  );
}

Future<void> editMessageAttachmentAltText(
  BuildContext context,
  WidgetRef ref, {
  required String messageId,
  required Attachment attachment,
  bool useRootNavigator = true,
}) async {
  final String? description = await showAttachmentAltTextSheet(
    context,
    attachment: attachment,
    useRootNavigator: useRootNavigator,
  );
  if (description == null || !context.mounted) {
    return;
  }
  await ref
      .read(chatViewModelProvider.notifier)
      .editAttachmentAltText(
        messageId: messageId,
        attachmentId: attachment.id,
        description: description.isEmpty ? null : description,
      );
}

class _AttachmentAltTextSheetBody extends ConsumerStatefulWidget {
  const _AttachmentAltTextSheetBody({
    required this.attachment,
    required this.onClose,
    required this.useRootNavigator,
  });

  final Attachment attachment;
  final VoidCallback onClose;
  final bool useRootNavigator;

  @override
  ConsumerState<_AttachmentAltTextSheetBody> createState() =>
      _AttachmentAltTextSheetBodyState();
}

class _AttachmentAltTextSheetBodyState
    extends ConsumerState<_AttachmentAltTextSheetBody> {
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.attachment.description ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _executeSaveAndClose() {
    final String description = _descriptionController.text.trim();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(
      context,
      rootNavigator: widget.useRootNavigator,
    ).pop(description.isEmpty ? '' : description);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = StarLocalizations.of(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StarInput.multiline(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              label: l10n.chatAttachmentDescriptionLabel,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StarButton.secondary(
                    onPressed: widget.onClose,
                    label: l10n.cancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StarButton.primary(
                    onPressed: _executeSaveAndClose,
                    label: l10n.save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
