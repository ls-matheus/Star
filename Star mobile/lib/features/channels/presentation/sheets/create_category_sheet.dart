import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/input/star_input.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class CreateCategorySheet {
  CreateCategorySheet._();

  static Future<String?> show(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    var currentName = '';
    final ValueNotifier<bool> nameValid = ValueNotifier<bool>(false);

    return StarModal.show<String>(
      context,
      title: l10n.guildNavbarCreateCategory,
      builder: (BuildContext dialogContext, VoidCallback close) {
        return StarInput(
          label: l10n.guildNavbarNameLabel,
          hint: l10n.guildNavbarNewCategoryHint,
          maxLength: 100,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (String value) {
            currentName = value;
            nameValid.value = value.trim().isNotEmpty;
          },
          onSubmitted: (_) {
            final String value = currentName.trim();
            if (value.isNotEmpty) {
              Navigator.of(context).pop(value);
            }
          },
        );
      },
      actions: <Widget>[
        ValueListenableBuilder<bool>(
          valueListenable: nameValid,
          builder: (BuildContext _, bool isValid, Widget? _) =>
              StarButton.primary(
                onPressed: isValid
                    ? () => Navigator.of(context).pop(currentName.trim())
                    : null,
                label: l10n.guildNavbarCreateCategory,
              ),
        ),
        const SizedBox(height: 8),
        StarButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          label: l10n.cancel,
        ),
      ],
    );
  }
}
