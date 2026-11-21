import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/domain/guild/expressions/guild_sticker_settings_entry.dart';
import 'package:star_app/features/settings/utils/guild/guild_expression_name_validation.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

const int kGuildStickerTagLimit = 10;

Future<({String name, String description, List<String> tags})?>
showGuildStickerFormSheet({
  required BuildContext context,
  required String title,
  required String submitLabel,
  GuildStickerSettingsEntry? initial,
  Uint8List? previewBytes,
}) {
  return StarBottomSheet.show<
    ({String name, String description, List<String> tags})?
  >(
    context,
    title: title,
    builder: (BuildContext sheetContext, VoidCallback close) {
      return _GuildStickerFormSheet(initial: initial, submitLabel: submitLabel);
    },
  );
}

class _GuildStickerFormSheet extends ConsumerStatefulWidget {
  const _GuildStickerFormSheet({
    required this.initial,
    required this.submitLabel,
  });

  final GuildStickerSettingsEntry? initial;
  final String submitLabel;

  @override
  ConsumerState<_GuildStickerFormSheet> createState() =>
      _GuildStickerFormSheetState();
}

class _GuildStickerFormSheetState
    extends ConsumerState<_GuildStickerFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;
  late List<String> _tags;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.initial?.description ?? '',
    );
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.initial?.tags ?? const <String>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.s4,
        context.layout.s4,
        context.layout.s4,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StarInput(
            controller: _nameController,
            label: l10n.guildSettingsStickerNameLabel,
            hint: l10n.guildSettingsStickerNameHint,
          ),
          SizedBox(height: context.layout.s3),
          StarInput(
            controller: _descriptionController,
            label: l10n.guildSettingsStickerDescriptionLabel,
            hint: l10n.guildSettingsStickerDescriptionHint,
            maxLines: 3,
          ),
          SizedBox(height: context.layout.s3),
          Text(
            l10n.guildSettingsStickerTagsLabel(
              _tags.length,
              kGuildStickerTagLimit,
            ),
            style: context.textStyles.bodySmall.copyWith(
              color: context.colors.textPrimaryMuted,
            ),
          ),
          SizedBox(height: context.layout.s2),
          Row(
            children: <Widget>[
              Expanded(
                child: StarInput(
                  controller: _tagController,
                  hint: l10n.guildSettingsStickerTagHint,
                ),
              ),
              SizedBox(width: context.layout.s2),
              StarButton.secondary(
                label: l10n.guildSettingsStickerTagAdd,
                onPressed: _addTag,
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...<Widget>[
            SizedBox(height: context.layout.s2),
            Wrap(
              spacing: context.layout.s2,
              runSpacing: context.layout.s2,
              children: _tags
                  .map(
                    (String tag) => InputChip(
                      label: Text(tag),
                      onDeleted: () => setState(() => _tags.remove(tag)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (_error != null) ...<Widget>[
            SizedBox(height: context.layout.s2),
            Text(
              _error!,
              style: context.textStyles.bodySmall.copyWith(
                color: context.colors.textDanger,
              ),
            ),
          ],
          SizedBox(height: context.layout.s4),
          StarButton.primary(label: widget.submitLabel, onPressed: _submit),
        ],
      ),
    );
  }

  void _addTag() {
    final String tag = _tagController.text.trim();
    if (tag.isEmpty || _tags.length >= kGuildStickerTagLimit) {
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _submit() {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String name = _nameController.text.trim();
    final String description = _descriptionController.text.trim();
    final GuildExpressionNameValidationError? nameError =
        validateGuildStickerName(name);
    if (nameError == GuildExpressionNameValidationError.tooShort &&
        name.isEmpty) {
      setState(() => _error = l10n.guildSettingsStickerNameRequired);
      return;
    }
    if (nameError == GuildExpressionNameValidationError.tooShort) {
      setState(() => _error = l10n.guildSettingsStickerNameTooShort);
      return;
    }
    if (nameError == GuildExpressionNameValidationError.tooLong) {
      setState(() => _error = l10n.guildSettingsStickerNameTooLong);
      return;
    }
    if (validateGuildStickerDescription(description) != null) {
      setState(() => _error = l10n.guildSettingsStickerDescriptionTooLong);
      return;
    }
    Navigator.of(context).pop((
      name: name,
      description: description,
      tags: List<String>.from(_tags),
    ));
  }
}
