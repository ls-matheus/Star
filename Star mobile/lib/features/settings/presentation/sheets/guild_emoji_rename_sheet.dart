import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/utils/guild/guild_expression_name_validation.dart';
import 'package:star_app/features/ui/bottom_sheet/star_bottom_sheet.dart';
import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

Future<String?> showGuildEmojiRenameSheet({
  required BuildContext context,
  required String initialName,
}) {
  return StarBottomSheet.show<String>(
    context,
    title: StarLocalizations.of(context).guildSettingsEmojiRenameTitle,
    builder: (BuildContext sheetContext, _) {
      return _GuildEmojiRenameSheet(initialName: initialName);
    },
  );
}

class _GuildEmojiRenameSheet extends StatefulWidget {
  const _GuildEmojiRenameSheet({required this.initialName});

  final String initialName;

  @override
  State<_GuildEmojiRenameSheet> createState() => _GuildEmojiRenameSheetState();
}

class _GuildEmojiRenameSheetState extends State<_GuildEmojiRenameSheet> {
  late final TextEditingController _nameController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
            hint: l10n.guildSettingsEmojiRenameHint,
            autofocus: true,
          ),
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
          StarButton.primary(label: l10n.save, onPressed: _submit),
        ],
      ),
    );
  }

  void _submit() {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final String name = _nameController.text.trim();
    final GuildExpressionNameValidationError? validation =
        validateGuildEmojiName(name);
    if (validation == GuildExpressionNameValidationError.tooShort) {
      setState(() => _error = l10n.guildSettingsEmojiNameTooShort);
      return;
    }
    if (validation == GuildExpressionNameValidationError.tooLong) {
      setState(() => _error = l10n.guildSettingsEmojiNameTooLong);
      return;
    }
    if (validation == GuildExpressionNameValidationError.invalidCharacters) {
      setState(() => _error = l10n.guildSettingsEmojiInvalidNameTitle);
      return;
    }
    Navigator.of(context).pop(name);
  }
}
