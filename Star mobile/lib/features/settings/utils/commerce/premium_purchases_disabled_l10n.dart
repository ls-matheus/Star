import 'package:star_app/core/constants/contact_emails.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String premiumPurchasesDisabledMessage(
  StarLocalizations l10n, {
  required bool selfHosted,
}) {
  return selfHosted
      ? l10n.premiumPurchasesDisabledBodySelfHosted
      : l10n.premiumPurchasesDisabledBody(ContactEmails.support);
}

String premiumPlanUnavailableMessage(
  StarLocalizations l10n, {
  required bool selfHosted,
}) {
  return selfHosted
      ? l10n.premiumPlanUnavailableSelfHosted
      : l10n.premiumPlanUnavailable;
}
