import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/chat/presentation/widgets/pickers/picker_search_input.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/providers/input_modality_provider.dart';

class GuildExpressionSearchField extends StatelessWidget {
  const GuildExpressionSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.padding,
    super.key,
  });

  final EdgeInsetsGeometry? padding;

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ??
          (usesDesktopPointerUi(context)
              ? const EdgeInsets.only(bottom: 16)
              : EdgeInsets.fromLTRB(
                  context.layout.s4,
                  context.layout.s4,
                  context.layout.s4,
                  0,
                )),
      child: PickerSearchInput.inline(
        controller: controller,
        hintText: hintText,
        onChanged: onChanged,
      ),
    );
  }
}
