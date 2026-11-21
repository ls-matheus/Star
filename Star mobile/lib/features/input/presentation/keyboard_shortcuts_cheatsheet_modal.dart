import 'package:star_app/features/settings/presentation/widgets/user_shortcuts.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class KeyboardShortcutsCheatsheetModal {
  KeyboardShortcutsCheatsheetModal._();

  static Future<void> show(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return StarModal.show<void>(
      context,
      title: l10n.keybindActionShowShortcutsList,
      builder: (BuildContext context, VoidCallback close) {
        return const SizedBox(
          width: 640,
          child: SingleChildScrollView(
            child: DefaultShortcutsList(searchQuery: ''),
          ),
        );
      },
    );
  }
}
