import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/profile/providers/user_note_view_model.dart';
import 'package:star_app/features/ui/input/utf16_length_limiting_formatter.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

const int kUserNoteMaxLength = 256;

class UserProfileNoteEditSheet {
  UserProfileNoteEditSheet._();

  static Future<void> show(
    BuildContext context, {
    required String userId,
    String? initialNote,
  }) {
    return StarBottomSheet.show<void>(
      context,
      title: StarLocalizations.of(context).userProfileNoteTitle,
      useRootNavigator: true,
      builder: (sheetContext, close) {
        return _NoteEditor(
          userId: userId,
          initialNote: initialNote,
          onClose: close,
        );
      },
    );
  }
}

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({
    required this.userId,
    required this.initialNote,
    required this.onClose,
  });

  final String userId;
  final String? initialNote;
  final VoidCallback onClose;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = StarLocalizations.of(context);
    try {
      await ref
          .read(userNoteViewModelProvider(userId: widget.userId).notifier)
          .save(_controller.text);
      if (mounted) {
        widget.onClose();
      }
    } on Object {
      if (!mounted) {
        return;
      }
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.userProfileFailedSaveNote,
              variant: StarToastVariant.danger,
            ),
          );
    }
  }

  Future<void> _delete() async {
    try {
      await ref
          .read(userNoteViewModelProvider(userId: widget.userId).notifier)
          .delete();
      if (mounted) {
        widget.onClose();
      }
    } on Object {
      if (!mounted) {
        return;
      }
      final l10n = StarLocalizations.of(context);
      ref
          .read(toastProvider.notifier)
          .show(
            StarToast(
              message: l10n.userProfileFailedSaveNote,
              variant: StarToastVariant.danger,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);
    final hasInitial =
        widget.initialNote != null && widget.initialNote!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StarInput.multiline(
            controller: _controller,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              Utf16LengthLimitingTextInputFormatter(kUserNoteMaxLength),
            ],
            showCounter: true,
            counterMax: kUserNoteMaxLength,
            minLines: 4,
            maxLines: 8,
          ),
          SizedBox(height: layout.s4),
          Row(
            children: [
              if (hasInitial) ...[
                Expanded(
                  child: StarButton.dangerPrimary(
                    label: l10n.userProfileNoteDelete,
                    onPressedAsync: _delete,
                  ),
                ),
                SizedBox(width: layout.s2),
              ],
              Expanded(
                child: StarButton.primary(
                  label: l10n.userProfileNoteSave,
                  onPressedAsync: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
