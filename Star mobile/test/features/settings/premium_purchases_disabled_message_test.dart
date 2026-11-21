import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:star_app/core/api/star_client_provider.dart';
import 'package:star_app/core/constants/contact_emails.dart';
import 'package:star_app/core/instance/instance_runtime_config.dart';
import 'package:star_app/core/providers/instance/instance_runtime_config_provider.dart';
import 'package:star_app/core/theme/star_layout_theme.dart';
import 'package:star_app/core/theme/star_text_theme.dart';
import 'package:star_app/core/theme/star_theme.dart';
import 'package:star_app/core/theme/themes/dark.dart';
import 'package:star_app/features/settings/presentation/widgets/premium/store/premium_store_bar.dart';
import 'package:star_app/features/settings/providers/commerce/plutonium_store_provider.dart';
import 'package:star_app/features/settings/services/premium_checkout_service.dart';
import 'package:star_app/features/settings/utils/commerce/plutonium_store_bar_mode.dart';
import 'package:star_app/features/settings/utils/commerce/premium_purchases_disabled_l10n.dart';
import 'package:star_app/features/settings/utils/commerce/premium_subscription_status.dart';
import 'package:star_app/material_ui.dart';
import 'package:star_dart/export.dart';

import '../../helpers/test_l10n.dart';

const String _hostedBody =
    'Purchases are disabled for this account. '
    'Contact support@star.invalid if this looks wrong.';
const String _selfHostedBody =
    'Purchases are disabled for this account. '
    "Contact this instance's administrators if this looks wrong.";

const InstanceRuntimeConfig _selfHostedConfig = InstanceRuntimeConfig(
  productName: 'Example',
  selfHosted: true,
  stripeEnabled: true,
  emailsEnabled: true,
  voiceEnabled: true,
  presignedAttachmentUploads: true,
  gifEnabled: true,
  blueskyEnabled: true,
  gifAttributionRequired: false,
  singleCommunity: false,
  directMessagesDisabled: false,
  registrationClosed: false,
  adminRegistrationUrlsEnabled: false,
  collectDateOfBirth: true,
);

const PremiumSubscriptionStatus _status = PremiumSubscriptionStatus(
  isPremium: false,
  isVisionary: false,
  hasEverPurchased: false,
  premiumWillCancel: false,
  billingCycle: null,
  actualPremiumUntil: null,
  isGiftSubscription: false,
  gracePeriodInfo: PremiumGracePeriodInfo(
    isInGracePeriod: false,
    isExpired: false,
    showExpiredState: false,
  ),
  shouldShowPremiumCard: false,
  shouldUseCancelQuickAction: false,
  shouldUseReactivateQuickAction: false,
);

class _PurchaseDisabledBillingApi implements BillingApi {
  @override
  Future<UrlResponse> createCheckoutSession({
    required CreateCheckoutSessionRequest body,
  }) {
    final RequestOptions options = RequestOptions(path: '/checkout');
    throw DioException(
      requestOptions: options,
      response: Response<Object?>(
        requestOptions: options,
        statusCode: 403,
        data: const <String, dynamic>{'reason': 'purchase_disabled'},
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClient extends StarClient {
  _FakeClient() : super(Dio());

  final BillingApi _billing = _PurchaseDisabledBillingApi();

  @override
  BillingApi get billing => _billing;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required InstanceRuntimeConfig config,
}) {
  final colorTheme = buildDarkColorTheme();
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        starClientProvider.overrideWithValue(_FakeClient()),
        instanceRuntimeConfigProvider.overrideWithValue(config),
      ],
      child: MaterialApp(
        locale: kTestLocale,
        localizationsDelegates: starLocalizationsDelegates,
        supportedLocales: StarLocalizations.supportedLocales,
        theme: buildStarTheme(
          colorTheme: colorTheme,
          textTheme: StarTextTheme.fromColors(colorTheme),
          layoutTheme: StarLayoutTheme.scaled(),
        ),
        home: Scaffold(body: child),
      ),
    ),
  );
}

Widget _storeBar() {
  return PremiumStoreBar(
    mode: PremiumStoreBarMode.subscribe,
    status: _status,
    store: const PremiumStoreState(
      purchaseBlockedReason: StorePurchaseBlockedReason.purchaseDisabled,
    ),
    purchaseDisabled: false,
    purchaseDisabledMessage: null,
    onBuy: (_) {},
    onRetry: () {},
    onManage: null,
  );
}

Widget _checkoutTrigger() {
  return Consumer(
    builder: (context, ref, _) => TextButton(
      onPressed: () => startPremiumCheckout(
        context: context,
        ref: ref,
        plan: PremiumCheckoutPlan.monthly,
        priceIds: const PriceIdsResponse(
          currency: 'USD',
          giftCurrency: 'USD',
          distribution: null,
          monthly: 'price_monthly',
        ),
      ),
      child: const Text('checkout'),
    ),
  );
}

void main() {
  test('the hosted message names the star.invalid support mailbox', () {
    expect(ContactEmails.support, 'support@star.invalid');
    expect(
      premiumPurchasesDisabledMessage(testL10n, selfHosted: false),
      _hostedBody,
    );
  });

  test('the self-hosted message names no mailbox', () {
    expect(
      premiumPurchasesDisabledMessage(testL10n, selfHosted: true),
      _selfHostedBody,
    );
  });

  test('no locale names a mailbox on a self-hosted instance', () {
    for (final locale in StarLocalizations.supportedLocales) {
      final StarLocalizations l10n = lookupStarLocalizations(locale);
      final String hosted = premiumPurchasesDisabledMessage(
        l10n,
        selfHosted: false,
      );
      final String selfHosted = premiumPurchasesDisabledMessage(
        l10n,
        selfHosted: true,
      );
      expect(hosted, contains(ContactEmails.support), reason: '$locale');
      expect(hosted, isNot(contains('star.invalid')), reason: '$locale');
      expect(selfHosted, isNot(contains('@')), reason: '$locale');
      expect(selfHosted, isNot(contains('{')), reason: '$locale');
      expect(selfHosted, isNot(hosted), reason: '$locale');
    }
  });

  test(
    'the plan unavailable message drops support on a self-hosted instance',
    () {
      for (final locale in StarLocalizations.supportedLocales) {
        final StarLocalizations l10n = lookupStarLocalizations(locale);
        expect(
          premiumPlanUnavailableMessage(l10n, selfHosted: false),
          l10n.premiumPlanUnavailable,
          reason: '$locale',
        );
        expect(
          premiumPlanUnavailableMessage(l10n, selfHosted: true),
          l10n.premiumPlanUnavailableSelfHosted,
          reason: '$locale',
        );
      }
      expect(
        premiumPlanUnavailableMessage(testL10n, selfHosted: true),
        "This plan isn't available. Contact the administrators of this instance.",
      );
    },
  );

  testWidgets('the store bar names the support mailbox when hosted', (
    tester,
  ) async {
    await _pump(tester, _storeBar(), config: InstanceRuntimeConfig.defaults);

    expect(find.text(_hostedBody), findsOneWidget);
    expect(find.text(_selfHostedBody), findsNothing);
  });

  testWidgets('the store bar names the administrators when self-hosted', (
    tester,
  ) async {
    await _pump(tester, _storeBar(), config: _selfHostedConfig);

    expect(find.text(_selfHostedBody), findsOneWidget);
    expect(find.textContaining('@star'), findsNothing);
  });

  testWidgets('the checkout error names the support mailbox when hosted', (
    tester,
  ) async {
    await _pump(
      tester,
      _checkoutTrigger(),
      config: InstanceRuntimeConfig.defaults,
    );
    await tester.tap(find.text('checkout'));
    await tester.pumpAndSettle();

    expect(find.text(testL10n.premiumPurchasesDisabledTitle), findsOneWidget);
    expect(find.text(_hostedBody), findsOneWidget);
  });

  testWidgets('the checkout error names the administrators when self-hosted', (
    tester,
  ) async {
    await _pump(tester, _checkoutTrigger(), config: _selfHostedConfig);
    await tester.tap(find.text('checkout'));
    await tester.pumpAndSettle();

    expect(find.text(testL10n.premiumPurchasesDisabledTitle), findsOneWidget);
    expect(find.text(_selfHostedBody), findsOneWidget);
    expect(find.textContaining('@star'), findsNothing);
  });
}
