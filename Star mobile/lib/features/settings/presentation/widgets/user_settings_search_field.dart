import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/picker_search_input.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

class UserSettingsSearchField extends StatelessWidget {
  const UserSettingsSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
    this.padding,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.only(bottom: context.layout.s4),
      child: TapRegion(
        onTapOutside: (_) =>
            (focusNode ?? FocusManager.instance.primaryFocus)?.unfocus(),
        child: PickerSearchInput.inline(
          controller: controller,
          focusNode: focusNode,
          hintText: l10n.userSettingsSearchPlaceholder,
          onChanged: onChanged,
          onCleared: onClear,
          desktopSettingsStyle: true,
        ),
      ),
    );
  }
}
