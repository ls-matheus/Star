import 'package:star_app/features/ui/button/star_button.dart';
import 'package:star_app/features/ui/button/star_button_size.dart';
import 'package:star_app/material_ui.dart';

class StarNagbarButton extends StatelessWidget {
  const StarNagbarButton({
    required this.label,
    required this.onPressed,
    required this.isMobile,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isMobile;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return StarButton.inverted(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      fitContent: true,
      size: isMobile ? StarButtonSize.compact : StarButtonSize.superCompact,
    );
  }
}
