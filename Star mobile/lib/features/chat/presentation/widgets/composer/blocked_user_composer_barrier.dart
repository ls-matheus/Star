import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/ui/ui.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/icons/phosphor.dart';

class BlockedUserComposerBarrier extends StatelessWidget {
  const BlockedUserComposerBarrier({
    required this.username,
    required this.onUnblock,
    super.key,
  });

  final String username;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: context.colors.chatInputBackground,
            border: Border(
              top: BorderSide(color: context.colors.userAreaDividerColor),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: PhosphorIcon(
                  PhosphorIconsFill.info,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.userProfileOpenBlockedDmDescription(username),
                  style: context.textStyles.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StarButton.secondary(
                label: l10n.blockedUserComposerBarrierAction,
                size: StarButtonSize.compact,
                fitContent: true,
                onPressed: onUnblock,
              ),
            ],
          ),
        ),
        Container(
          height: MediaQuery.paddingOf(context).bottom,
          decoration: BoxDecoration(color: context.colors.chatInputBackground),
        ),
      ],
    );
  }
}
