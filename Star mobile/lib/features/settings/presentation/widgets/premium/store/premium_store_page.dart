import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:star_app/core/premium/current_user_entitlements_provider.dart';
import 'package:star_app/core/premium/external_purchase_links_provider.dart';
import 'package:star_app/core/providers/app/account_user_id.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_theme_extension.dart';
import 'package:star_app/features/settings/presentation/user_settings_modal.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_backdrop.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_bar.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_hero_art.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_hero_band.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_hero_highlights.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_marketing.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_style.dart';
import 'package:star_app/features/settings/providers/commerce/plutonium_store_provider.dart';
import 'package:star_app/features/settings/providers/commerce/premium_settings_state_provider.dart';
import 'package:star_app/features/settings/providers/commerce/store_billing_context_provider.dart';
import 'package:star_app/features/settings/providers/view_models/user_settings_view_model.dart';
import 'package:star_app/features/settings/services/plutonium_store_products.dart';
import 'package:star_app/features/settings/services/premium_checkout_service.dart';
import 'package:star_app/features/settings/utils/commerce/plutonium_store_bar_mode.dart';
import 'package:star_app/features/settings/utils/commerce/premium_subscription_manage.dart';
import 'package:star_app/features/settings/utils/commerce/premium_subscription_status.dart';
import 'package:star_app/features/shell/providers/user/current_user_private_provider.dart';
import 'package:star_app/features/ui/modal/star_modal.dart';
import 'package:star_app/features/ui/text_link/star_text_link.dart';
import 'package:star_app/features/ui/toast/star_toast.dart';
import 'package:star_app/features/ui/toast/toast_provider.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

const String _kDonateUrl = 'https://star.invalid/donate';

class PremiumStorePage extends ConsumerStatefulWidget {
  const PremiumStorePage({this.scrollController, super.key});

  final ScrollController? scrollController;

  @override
  ConsumerState<PremiumStorePage> createState() => _PremiumStorePageState();
}

class _PremiumStorePageState extends ConsumerState<PremiumStorePage> {
  ScrollController? _ownedScrollController;
  bool _ownershipCheckPending = false;

  ScrollController get _scrollController =>
      widget.scrollController ?? _ownedScrollController!;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController();
    }
    unawaited(Future<void>.microtask(_refreshOnOpen));
  }

  void _refreshOnOpen() {
    if (!mounted) {
      return;
    }
    ref.invalidate(storefrontCountryProvider);
    final PremiumStoreNotifier notifier = ref.read(
      premiumStoreProvider.notifier,
    );
    if (ref.read(storeBillingContextProvider).hasError) {
      notifier.retry();
    }
    _ownershipCheckPending = true;
    _checkOwnershipWhenReady(ref.read(premiumStoreProvider));
  }

  void _checkOwnershipWhenReady(PremiumStoreState store) {
    if (!_ownershipCheckPending ||
        store.loading ||
        store.loadFailed ||
        store.storeUnavailable) {
      return;
    }
    _ownershipCheckPending = false;
    unawaited(ref.read(premiumStoreProvider.notifier).checkOwnership());
  }

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final StarLocalizations l10n = StarLocalizations.of(context);
    final PremiumStoreState store = ref.watch(premiumStoreProvider);
    ref.listen(premiumStoreProvider, (
      PremiumStoreState? previous,
      PremiumStoreState next,
    ) {
      if (previous != null && next.errorSerial != previous.errorSerial) {
        unawaited(_showPurchaseError(l10n));
      }
      _checkOwnershipWhenReady(next);
    });

    final UserSettingsViewState settings = ref.watch(
      userSettingsViewModelProvider,
    );
    final UserPrivateResponse? user = ref.watch(
      currentUserPrivateReadProvider(watchAccountUserId(ref)),
    );
    final bool purchaseDisabled =
        settings.isKnownUnclaimed || !(user?.verified ?? false);
    final bool needsVerifiedEmail =
        !settings.isKnownUnclaimed && !(user?.verified ?? false);
    final String? purchaseDisabledMessage = settings.isKnownUnclaimed
        ? l10n.premiumClaimAccountToPurchase
        : needsVerifiedEmail
        ? l10n.premiumVerifyEmailToPurchase
        : null;
    final PremiumSubscriptionStatus status = computePremiumSubscriptionStatus(
      premiumState: ref.watch(premiumSettingsStateProvider).value,
      effectiveIsPremium: ref
          .watch(currentUserEntitlementsProvider(readAccountUserId(ref)))
          .isEffectivelyPremium,
      userPrivate: user,
    );
    final PremiumManageAction? manage = premiumManageAction(
      surface: PremiumManageSurface.store,
      provider: status.subscriptionProvider,
      manageUrl: status.manageUrl,
      currentStore: store.billingStore,
    );
    final PremiumStoreBarMode mode = premiumStoreBarMode(
      status: status,
      purchasePending: store.purchasePending,
      manageOnDevice: manage != null,
    );
    VoidCallback? onManage;
    if (manage != null) {
      final PremiumManageAction action = manage;
      onManage = () => unawaited(openPremiumManageAction(context, ref, action));
    }
    final String? otherStoreNotice =
        premiumStorePurchaseBlockedByOtherPlatform(
          reason: store.purchaseBlockedReason,
          blockingProvider: store.blockingProvider,
          currentStore: store.billingStore,
        )
        ? l10n.storePlutoniumAlreadySubscribed
        : null;

    final bool selfHosted = ref.watch(
      instanceRuntimeConfigProvider.select((config) => config.selfHosted),
    );
    final String heroAsset = premiumStoreHeroArtAsset(selfHosted: selfHosted);

    return PremiumStoreBackdrop(
      bar: PremiumStoreBar(
        mode: mode,
        status: status,
        store: store,
        purchaseDisabled: purchaseDisabled,
        purchaseDisabledMessage: purchaseDisabledMessage,
        onVerifyEmail: needsVerifiedEmail
            ? () => unawaited(
                UserSettingsModal.show(context, openSecuritySection: true),
              )
            : null,
        onBuy: (PremiumStorePlan plan) {
          unawaited(ref.read(premiumStoreProvider.notifier).buy(plan));
        },
        onRetry: ref.read(premiumStoreProvider.notifier).retry,
        onManage: onManage,
        onRestore:
            store.billingStore == PremiumBillingStore.appStore &&
                !store.storeUnavailable &&
                !store.loadFailed
            ? () => _restore(l10n)
            : null,
        otherStoreNotice: otherStoreNotice,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumStoreHeroBand(
              heroArtAsset: heroAsset,
              title: l10n.userSettingsNavStarPlutonium,
              scrollController: _scrollController,
              footer: selfHosted || defaultTargetPlatform == TargetPlatform.iOS
                  ? null
                  : const _DonateLine(),
              highlights: const PremiumStoreHeroHighlights(),
            ),
            const PremiumStoreMarketingSections(),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(StarLocalizations l10n) async {
    final PremiumRestoreOutcome outcome = await ref
        .read(premiumStoreProvider.notifier)
        .restore();
    if (!mounted) {
      return;
    }
    ref.read(toastProvider.notifier).show(switch (outcome) {
      PremiumRestoreOutcome.restored => StarToast(
        message: l10n.storePlutoniumRestoreDone,
        variant: StarToastVariant.success,
      ),
      PremiumRestoreOutcome.nothingToRestore => StarToast(
        message: l10n.storePlutoniumRestoreNothing,
      ),
      PremiumRestoreOutcome.ownedByOtherAccount => StarToast(
        message: l10n.storePlutoniumOwnedByOtherAccount,
        variant: StarToastVariant.warning,
      ),
      PremiumRestoreOutcome.failed => StarToast(
        message: l10n.storePlutoniumRestoreFailed,
        variant: StarToastVariant.danger,
      ),
    });
  }

  Future<void> _showPurchaseError(StarLocalizations l10n) async {
    if (!mounted) {
      return;
    }
    final bool claimFailed =
        ref.read(premiumStoreProvider).lastError ==
        PremiumStoreError.claimFailed;
    await StarModal.show<void>(
      context,
      title: claimFailed
          ? l10n.storePlutoniumClaimFailedTitle
          : l10n.premiumCheckoutStartFailedTitle,
      description: claimFailed
          ? l10n.storePlutoniumClaimFailedBody
          : l10n.premiumCheckoutStartFailedBody,
      centered: true,
      actionsBuilder: (pop) => [
        TextButton(onPressed: () => pop(), child: Text(l10n.okay)),
      ],
      builder: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _DonateLine extends StatelessWidget {
  const _DonateLine();

  @override
  Widget build(BuildContext context) {
    final PremiumStoreStyle style = PremiumStoreStyle.of(context);
    final StarLocalizations l10n = StarLocalizations.of(context);
    final TextStyle muted = context.textStyles.bodySmall.copyWith(
      color: style.inkSoft,
    );
    return Text.rich(
      TextSpan(
        style: muted,
        children: [
          TextSpan(text: l10n.storePlutoniumDonatePrompt),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: MediaQuery.withNoTextScaling(
              child: StarTextLink(
                text: l10n.storePlutoniumDonateLink,
                url: _kDonateUrl,
                style: muted.copyWith(
                  color: style.ink,
                  decoration: TextDecoration.underline,
                  decorationColor: style.inkFaint,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
