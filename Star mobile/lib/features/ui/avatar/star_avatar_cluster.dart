import 'package:star_app/core/media/star_media_url.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/avatar/star_avatar_status_badge.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

const double kAvatarClusterMemberScale = 0.625;
const double kAvatarClusterCutoutScale = 0.084;
const double _kFallbackGlyphScale = 0.5;

class AvatarClusterMember {
  final String userId;
  final String? imageUrl;

  const AvatarClusterMember({required this.userId, this.imageUrl});

  String? get resolvedImageUrl {
    if (imageUrl != null) {
      return imageUrl;
    }
    return StarMediaUrl.defaultAvatar(userId: userId);
  }
}

class StarAvatarCluster extends StatelessWidget {
  const StarAvatarCluster({
    this.iconUrl,
    this.isTyping = false,
    this.members = const [],
    this.size = 32,
    super.key,
  });

  final String? iconUrl;
  final bool isTyping;
  final List<AvatarClusterMember> members;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget avatar;
    if (iconUrl != null) {
      avatar = StarNetworkAvatarImage(
        size: size,
        imageUrl: iconUrl,
        errorBuilder: () => _buildFallback(context),
      );
    } else if (members.length >= 2) {
      avatar = _buildStack();
    } else {
      avatar = _buildFallback(context);
    }
    return StarAvatarStatusBadge(
      size: size,
      isTyping: isTyping,
      child: avatar,
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.brandPrimary,
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        PhosphorIconsFill.users,
        size: size * _kFallbackGlyphScale,
        color: context.colors.textOnBrandPrimary,
      ),
    );
  }

  Widget _buildStack() {
    final double memberSize = size * kAvatarClusterMemberScale;
    final double frontOffset = size - memberSize;
    final Rect frontCutout = Rect.fromCircle(
      center: Offset(
        frontOffset + memberSize / 2,
        frontOffset + memberSize / 2,
      ),
      radius: memberSize / 2 + size * kAvatarClusterCutoutScale,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            start: 0,
            child: ClipPath(
              clipper: _StackBackClipper(
                memberSize: memberSize,
                frontCutout: frontCutout,
              ),
              child: _buildMemberCircle(members[0], memberSize),
            ),
          ),
          PositionedDirectional(
            top: frontOffset,
            start: frontOffset,
            child: _buildMemberCircle(members[1], memberSize),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCircle(AvatarClusterMember member, double memberSize) {
    return StarNetworkAvatarImage(
      size: memberSize,
      imageUrl: member.resolvedImageUrl,
      fallbackImageUrl: StarMediaUrl.defaultAvatar(userId: member.userId),
    );
  }
}

class _StackBackClipper extends CustomClipper<Path> {
  const _StackBackClipper({
    required this.memberSize,
    required this.frontCutout,
  });

  final double memberSize;
  final Rect frontCutout;

  @override
  Path getClip(Size size) {
    return Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromLTWH(0, 0, memberSize, memberSize)),
      Path()..addOval(frontCutout),
    );
  }

  @override
  bool shouldReclip(covariant _StackBackClipper oldClipper) =>
      memberSize != oldClipper.memberSize ||
      frontCutout != oldClipper.frontCutout;
}
