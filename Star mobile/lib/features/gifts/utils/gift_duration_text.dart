import 'package:flutter/foundation.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';
import 'package:star_app/shared/utils/display_name.dart';
import 'package:star_dart/export.dart';

const String kPremiumProductName = 'Plutonium';

bool giftClaimBlockedInApp(GiftCodeResponse gift) {
  return defaultTargetPlatform == TargetPlatform.iOS &&
      gift.durationQuantity == 0 &&
      !gift.redeemed;
}

String giftDurationText(StarLocalizations l10n, GiftCodeResponse gift) {
  if (gift.durationQuantity == 0) {
    return l10n.embedGiftVisionaryLifetime(kPremiumProductName);
  }
  return switch (gift.durationType) {
    GiftCodeDurationTypeSchema.days => l10n.embedGiftDurationDays(
      gift.durationQuantity,
      kPremiumProductName,
    ),
    GiftCodeDurationTypeSchema.weeks => l10n.embedGiftDurationWeeks(
      gift.durationQuantity,
      kPremiumProductName,
    ),
    GiftCodeDurationTypeSchema.months => l10n.embedGiftDurationMonths(
      gift.durationQuantity,
      kPremiumProductName,
    ),
    GiftCodeDurationTypeSchema.years => l10n.embedGiftDurationYears(
      gift.durationQuantity,
      kPremiumProductName,
    ),
    GiftCodeDurationTypeSchema.$unknown => l10n.embedGiftDurationMonths(
      gift.durationQuantity,
      kPremiumProductName,
    ),
  };
}

String giftCreatorDisplayName(UserPartialResponse creator) {
  return resolveDisplayName(
    username: creator.username,
    globalName: creator.globalName,
  );
}
