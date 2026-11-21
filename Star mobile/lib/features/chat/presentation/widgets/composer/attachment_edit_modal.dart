import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/features/chat/domain/message.dart';
import 'package:star_app/features/chat/domain/pending_attachment.dart';
import 'package:star_app/features/chat/providers/upload/cloud_upload_controller.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/toggle_switch/star_toggle_switch.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class AttachmentEditModal {
  AttachmentEditModal._();

  static Future<void> show(
    BuildContext context, {
    required String channelId,
    required PendingAttachment attachment,
  }) {
    return StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).chatAttachmentEditTitle,
      builder: (BuildContext sheetContext, VoidCallback close) {
        return _AttachmentEditSheetBody(
          channelId: channelId,
          attachment: attachment,
          onClose: close,
        );
      },
    );
  }
}

class _AttachmentEditSheetBody extends ConsumerStatefulWidget {
  const _AttachmentEditSheetBody({
    required this.channelId,
    required this.attachment,
    required this.onClose,
  });

  final String channelId;
  final PendingAttachment attachment;
  final VoidCallback onClose;

  @override
  ConsumerState<_AttachmentEditSheetBody> createState() =>
      _AttachmentEditSheetBodyState();
}

class _AttachmentEditSheetBodyState
    extends ConsumerState<_AttachmentEditSheetBody> {
  late final TextEditingController _filenameController;
  late final TextEditingController _descriptionController;
  late final ValueNotifier<bool> _spoilerNotifier;

  @override
  void initState() {
    super.initState();
    _filenameController = TextEditingController(
      text: widget.attachment.filename,
    );
    _descriptionController = TextEditingController(
      text: widget.attachment.description ?? '',
    );
    _spoilerNotifier = ValueNotifier<bool>(
      (widget.attachment.flags & attachmentFlagIsSpoiler) != 0,
    );
  }

  @override
  void dispose() {
    _filenameController.dispose();
    _descriptionController.dispose();
    _spoilerNotifier.dispose();
    super.dispose();
  }

  void _executeSaveAndClose() {
    final String name = _filenameController.text.trim();
    final String desc = _descriptionController.text.trim();
    int flags = widget.attachment.flags & ~attachmentFlagIsSpoiler;
    if (_spoilerNotifier.value) {
      flags |= attachmentFlagIsSpoiler;
    }
    ref
        .read(
          cloudUploadControllerProvider(
            readAccountUserId(ref),
            widget.channelId,
          ).notifier,
        )
        .updateAttachment(
          widget.attachment.id,
          filename: name.isNotEmpty ? name : widget.attachment.filename,
          description: desc.isEmpty ? null : desc,
          flags: flags,
        );
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StarInput(
              controller: _filenameController,
              label: StarLocalizations.of(
                context,
              ).chatAttachmentFilenameLabel,
            ),
            const SizedBox(height: 12),
            StarInput.multiline(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              label: StarLocalizations.of(
                context,
              ).chatAttachmentDescriptionLabel,
              hint: StarLocalizations.of(
                context,
              ).chatAttachmentDescriptionHint,
              maxLines: 4,
              minLines: 2,
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: _spoilerNotifier,
              builder: (BuildContext ctx, bool isSpoiler, _) {
                return StarToggleSwitch(
                  label: StarLocalizations.of(
                    context,
                  ).chatAttachmentSpoilerLabel,
                  value: isSpoiler,
                  onChanged: (bool v) => _spoilerNotifier.value = v,
                );
              },
            ),
            const SizedBox(height: 16),
            StarButton.primary(
              label: StarLocalizations.of(context).save,
              onPressed: _executeSaveAndClose,
            ),
          ],
        ),
      ),
    );
  }
}
