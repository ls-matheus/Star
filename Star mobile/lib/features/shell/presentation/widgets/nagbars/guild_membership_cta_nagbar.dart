import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/features/guilds/services/join_community_service.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/shell/providers/nagbar/guild_membership_cta_visibility_provider.dart';
import 'package:star_app/features/shell/providers/nagbar/nagbar_providers.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_app/shared/utils/api_error_presentation.dart';

const String kProductCommunityName = 'Star HQ';

class GuildMembershipCtaNagbar extends ConsumerStatefulWidget
    implements NagbarWidget {
  const GuildMembershipCtaNagbar({super.key});

  @override
  ConsumerState<GuildMembershipCtaNagbar> createState() =>
      _GuildMembershipCtaNagbarState();
}

class _GuildMembershipCtaNagbarState
    extends ConsumerState<GuildMembershipCtaNagbar> {
  bool _isSubmitting = false;

  Future<void> _joinCommunity() async {
    if (_isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);
    final StarLocalizations l10n = StarLocalizations.of(context);
    try {
      await joinCommunityViaInvite(
        ref: ref,
        rawInput: kStarHqInviteCode,
        l10n: l10n,
      );
      await ref
          .read(nagbarDismissalsProvider.notifier)
          .dismissGuildMembershipCta();
      ref.invalidate(guildMembershipCtaVisibleProvider);
    } on Object catch (error) {
      if (mounted) {
        await showApiError(context, ApiErrorAction.acceptInvite, error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final bool isMobile = isMobileLayout(context);
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: Theme.of(context).colorScheme.primary,
      textColor: Colors.white,
      dismissible: true,
      onDismiss: () => ref
          .read(nagbarDismissalsProvider.notifier)
          .dismissGuildMembershipCta(),
      child: StarNagbarContent(
        isMobile: isMobile,
        message: l10n.nagbarGuildMembershipCta(kProductCommunityName),
        onDismiss: () => ref
            .read(nagbarDismissalsProvider.notifier)
            .dismissGuildMembershipCta(),
        actions: StarNagbarButton(
          isMobile: isMobile,
          label: l10n.nagbarJoinCommunity(kProductCommunityName),
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _joinCommunity,
        ),
      ),
    );
  }
}
