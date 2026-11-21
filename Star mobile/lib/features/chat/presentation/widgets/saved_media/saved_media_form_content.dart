import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

List<String> parseSavedMediaTags(String value) => value
    .split(',')
    .map((String tag) => tag.trim())
    .where((String tag) => tag.isNotEmpty)
    .toSet()
    .toList(growable: false);

class SavedMediaFormContent extends StatefulWidget {
  const SavedMediaFormContent({
    required this.initialName,
    required this.initialAltText,
    required this.initialTags,
    required this.onSave,
    this.errorText,
    super.key,
  });

  final String initialName;
  final String initialAltText;
  final List<String> initialTags;
  final Future<void> Function({
    required String name,
    required String altText,
    required List<String> tags,
  })
  onSave;
  final String? errorText;

  @override
  State<SavedMediaFormContent> createState() => _SavedMediaFormContentState();
}

class _SavedMediaFormContentState extends State<SavedMediaFormContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _altTextController;
  late final TextEditingController _tagsController;
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _altTextController = TextEditingController(text: widget.initialAltText);
    _tagsController = TextEditingController(
      text: widget.initialTags.join(', '),
    );
    _canSave = widget.initialName.trim().isNotEmpty;
    _nameController.addListener(_handleNameChanged);
  }

  void _handleNameChanged() {
    final bool canSave = _nameController.text.trim().isNotEmpty;
    if (canSave != _canSave) {
      setState(() => _canSave = canSave);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    _altTextController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.onSave(
      name: _nameController.text,
      altText: _altTextController.text,
      tags: parseSavedMediaTags(_tagsController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final layout = context.layout;
    final colors = context.colors;

    return StarBottomSheetContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SavedMediaFormField(
            controller: _nameController,
            label: l10n.savedMediaFormNameLabel,
            hintText: l10n.savedMediaFormNameHint,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: layout.s3),
          _SavedMediaFormField(
            controller: _altTextController,
            label: l10n.savedMediaFormAltTextLabel,
            hintText: l10n.savedMediaFormAltTextHint,
            maxLines: 2,
            textInputAction: TextInputAction.next,
          ),
          SizedBox(height: layout.s3),
          _SavedMediaFormField(
            controller: _tagsController,
            label: l10n.savedMediaFormTagsLabel,
            hintText: l10n.savedMediaFormTagsHint,
            textInputAction: TextInputAction.done,
          ),
          if (widget.errorText != null) ...<Widget>[
            SizedBox(height: layout.s3),
            Text(
              widget.errorText!,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.accentDanger,
                fontSize: 13,
              ),
            ),
          ],
          SizedBox(height: layout.s4),
          StarButton.primary(
            label: l10n.save,
            onPressedAsync: _canSave ? _save : null,
          ),
        ],
      ),
    );
  }
}

class _SavedMediaFormField extends StatelessWidget {
  const _SavedMediaFormField({
    required this.controller,
    required this.label,
    this.hintText,
    this.maxLines = 1,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return StarInput(
      controller: controller,
      label: label,
      hint: hintText,
      maxLines: maxLines,
      textInputAction: textInputAction,
      style: context.textStyles.inputText.copyWith(
        color: context.colors.textPrimary,
      ),
    );
  }
}
