import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/features/settings/providers/commerce/premium_settings_state_provider.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/utils/commerce/premium_subscription_manage.dart';
import 'package:star_app/features/shell/presentation/responsive_layout.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/nagbar_widget.dart';
import 'package:star_app/features/shell/presentation/widgets/nagbars/premium_nagbar_manage.dart';
import 'package:star_app/features/shell/providers/nagbar/nagbar_providers.dart';
import 'package:star_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_button.dart';
import 'package:star_app/features/ui/nagbar/star_nagbar_content.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';
import 'package:intl/intl.dart';

const String kPremiumProductName = 'Plutonium';

class PremiumGracePeriodNagbar extends ConsumerStatefulWidget
    implements NagbarWidget {
  const PremiumGracePeriodNagbar({super.key});

  @override
  ConsumerState<PremiumGracePeriodNagbar> createState() =>
      _PremiumGracePeriodNagbarState();
}

class _PremiumGracePeriodNagbarState
    extends ConsumerState<PremiumGracePeriodNagbar> {
  bool _isLoading = false;

  Future<void> _openManage(PremiumManageAction action) {
    return openPremiumNagbarManage(
      context: context,
      ref: ref,
      action: action,
      setLoading: ({required bool loading}) =>
          setState(() => _isLoading = loading),
    );
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final UserSettingsViewState settings = ref.watch(
      userSettingsViewModelProvider,
    );
    final bool isMobile = isMobileLayout(context);
    final PremiumStateResponse? premium = ref
        .watch(premiumSettingsStateProvider)
        .value;
    final PremiumManageAction? manage = premiumNagbarManageAction(
      provider: premium?.subscriptionProvider,
      manageUrl: premium?.store?.manageUrl,
    );
    VoidCallback? onManage;
    if (!_isLoading && manage != null) {
      final PremiumManageAction action = manage;
      onManage = () => unawaited(_openManage(action));
    }
    final DateTime? graceEnd = premiumGraceEnd(
      premiumUntil: settings.premiumUntil,
      premiumGraceEndsAt: ref
          .watch(currentUserPrivateReadProvider(watchAccountUserId(ref)))
          ?.premiumGraceEndsAt,
    );
    final String graceDate = graceEnd == null
        ? ''
        : DateFormat.yMMMMd(
            Localizations.localeOf(context).toString(),
          ).format(graceEnd.toLocal());
    return StarNagbar(
      isMobile: isMobile,
      backgroundColor: const Color(0xFFF97316),
      textColor: Colors.white,
      dismissible: true,
      onDismiss: () => ref
          .read(nagbarDismissalsProvider.notifier)
          .dismissPremiumGracePeriod(),
      child: StarNagbarContent(
        isMobile: isMobile,
        message: manage == null
            ? l10n.nagbarPremiumGracePeriodNoAction(
                kPremiumProductName,
                graceDate,
              )
            : l10n.nagbarPremiumGracePeriod(kPremiumProductName, graceDate),
        onDismiss: () => ref
            .read(nagbarDismissalsProvider.notifier)
            .dismissPremiumGracePeriod(),
        actions: manage == null
            ? null
            : StarNagbarButton(
                isMobile: isMobile,
                label: l10n.nagbarManageSubscription,
                isLoading: _isLoading,
                onPressed: onManage,
              ),
      ),
    );
  }
}
