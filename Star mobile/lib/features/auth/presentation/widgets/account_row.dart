import 'dart:async';

import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/auth/domain/stored_account.dart';
import 'package:star_app/features/auth/presentation/widgets/instance_domain_icon.dart';
import 'package:star_app/features/ui/action_menu/star_action_menu.dart';
import 'package:star_app/features/ui/avatar/star_avatar.dart';
import 'package:star_app/features/ui/button/star_button_variant.dart';
import 'package:star_app/features/ui/selected_check/star_selected_check.dart';
import 'package:star_app/features/ui/tappable/star_tappable.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class AccountRow extends StatelessWidget {
  const AccountRow({
    required this.account,
    required this.isCurrent,
    required this.onTap,
    required this.onSignOut,
    super.key,
  });

  final StoredAccount account;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);

    return StarTappable(
      onTap: onTap,
      builder: (context, states) {
        final isHovered = states.contains(WidgetState.hovered);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: layout.s3,
            vertical: layout.s2,
          ),
          decoration: BoxDecoration(
            color: isHovered
                ? colors.backgroundTertiary
                : colors.backgroundSecondary,
            borderRadius: layout.radiusMd,
            border: StarButtonVariant.secondary.border(colors),
          ),
          child: Row(
            children: [
              StarAvatar.user(
                imageUrl: account.avatarUrl(),
                fallbackText: account.displayName,
                size: 36,
                showStatus: false,
                userId: account.userId,
              ),
              SizedBox(width: layout.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      account.identifier,
                      style: textStyles.bodyMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        InstanceDomainIcon(
                          isOfficial: account.isOfficialInstance,
                        ),
                        SizedBox(width: layout.s1),
                        Expanded(
                          child: Text(
                            account.instanceDomain,
                            style: textStyles.bodySmall.copyWith(
                              color: colors.textTertiary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (!account.isValid)
                      Text(
                        l10n.accountExpired,
                        style: textStyles.bodySmall.copyWith(
                          color: colors.textDanger,
                        ),
                      ),
                    if (account.isValid && isCurrent)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const StarSelectedCheck(size: 14),
                          SizedBox(width: layout.s1),
                          Text(
                            l10n.accountActive,
                            style: textStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              AccountOverflowButton(onSignOut: onSignOut),
            ],
          ),
        );
      },
    );
  }
}

class AccountOverflowButton extends StatelessWidget {
  const AccountOverflowButton({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final l10n = StarLocalizations.of(context);

    return StarTappable(
      semanticLabel: l10n.accountOverflowMenu,
      onTap: () {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) {
          return;
        }

        final position = renderBox.localToGlobal(
          Offset(0, renderBox.size.height),
        );

        unawaited(
          StarActionMenu.show(
            context,
            position: position,
            builder: (context, close) => [
              StarMenuItem(
                label: l10n.signOut,
                icon: PhosphorIconsBold.signOut,
                isDanger: true,
                onPressed: () {
                  close();
                  onSignOut();
                },
              ),
            ],
          ),
        );
      },
      builder: (context, states) {
        return SizedBox(
          width: layout.s8,
          height: layout.s8,
          child: Center(
            child: Icon(
              PhosphorIconsBold.dotsThreeVertical,
              size: 18,
              color: colors.textTertiary,
            ),
          ),
        );
      },
    );
  }
}
