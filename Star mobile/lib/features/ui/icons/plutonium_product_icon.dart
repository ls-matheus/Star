import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

const IconData kPlutoniumProductIcon = PhosphorIconsFill.atom;

class PlutoniumProductIcon extends StatelessWidget {
  const PlutoniumProductIcon({required this.size, this.color, super.key});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return PhosphorIcon(kPlutoniumProductIcon, size: size, color: color);
  }
}
