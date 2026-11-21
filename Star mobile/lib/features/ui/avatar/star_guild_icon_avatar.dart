import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/avatar/star_guild_acronym.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

const double _kCornerRatio = 0.32;
const double _kUnavailableIconSize = 22;

class StarGuildIconAvatar extends StatelessWidget {
  const StarGuildIconAvatar({
    required this.name,
    this.imageUrl,
    this.isUnavailable = false,
    this.isCircle = false,
    this.initialsColor,
    this.size = 36,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final bool isUnavailable;
  final bool isCircle;
  final Color? initialsColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final BorderRadius radius = BorderRadius.circular(
      isCircle ? size / 2 : size * _kCornerRatio,
    );
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.serverIconBackground,
          borderRadius: radius,
        ),
        child: ClipRRect(borderRadius: radius, child: _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.colors;
    if (isUnavailable) {
      return Center(
        child: PhosphorIcon(
          PhosphorIconsBold.exclamationMark,
          color: colors.textOnBrandPrimary,
          size: _kUnavailableIconSize,
        ),
      );
    }
    final String? url = imageUrl;
    final Color fallbackColor = initialsColor ?? colors.textTertiary;
    if (url == null) {
      return StarGuildAcronym(name: name, color: fallbackColor);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext _, Object _, StackTrace? _) =>
          StarGuildAcronym(name: name, color: fallbackColor),
    );
  }
}
