import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';

const double kUserProfileAvatarSize = 80;
const double kUserProfileAvatarRingWidth = 3.2;

class UserProfileIdentityAvatar extends StatelessWidget {
  const UserProfileIdentityAvatar({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.avatarColor,
    required this.showStatus,
    this.onTap,
    super.key,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int? avatarColor;
  final bool showStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = Container(
      padding: const EdgeInsets.all(kUserProfileAvatarRingWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.backgroundPrimary,
      ),
      child: StarAvatar.userPresence(
        fallbackText: displayName,
        userId: userId,
        imageUrl: avatarUrl,
        avatarColor: avatarColor,
        showStatus: showStatus,
        size: kUserProfileAvatarSize,
      ),
    );
    if (onTap == null) {
      return avatar;
    }
    return StarTappable(
      onTap: onTap,
      semanticLabel: StarLocalizations.of(context).statusChangeSheetTitle,
      excludeChildSemantics: true,
      builder: (BuildContext context, Set<WidgetState> states) => avatar,
    );
  }
}
