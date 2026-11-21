import 'package:star_app/features/dm/domain/create_dm_restriction.dart';
import 'package:star_app/features/dm/utils/create_dm_api_errors.dart';
import 'package:star_app/l10n/generated/star_localizations.dart';

String createDmButtonLabel(StarLocalizations l10n, int selectedCount) {
  if (selectedCount == 1) {
    return l10n.createDm;
  }
  return l10n.createGroupDm;
}

String createDmRestrictionTitle(
  StarLocalizations l10n,
  CreateDmRestriction restriction,
) {
  return switch (restriction) {
    CreateDmRestriction.unclaimed => l10n.claimAccountTitle,
    CreateDmRestriction.unverified => l10n.createDmVerifyYourEmail,
  };
}

String createDmRestrictionDescription(
  StarLocalizations l10n,
  CreateDmRestriction restriction,
) {
  return switch (restriction) {
    CreateDmRestriction.unclaimed => l10n.createDmClaimToStartDms,
    CreateDmRestriction.unverified => l10n.createDmVerifyToStartDms,
  };
}

String createDmRestrictionActionLabel(
  StarLocalizations l10n,
  CreateDmRestriction restriction,
) {
  return switch (restriction) {
    CreateDmRestriction.unclaimed => l10n.claimAccount,
    CreateDmRestriction.unverified => l10n.channelComposerBarrierVerifyEmail,
  };
}

String unaddableRecipientReasonLabel(
  StarLocalizations l10n,
  UnaddableRecipientReason reason,
) {
  return switch (reason) {
    UnaddableRecipientReason.unknownUser => l10n.createDmUnaddableUserNotFound,
    UnaddableRecipientReason.blocked => l10n.createDmUnaddableBlocked,
    UnaddableRecipientReason.notFriends => l10n.createDmUnaddableNotFriends,
    UnaddableRecipientReason.groupDmAddDisabled =>
      l10n.createDmUnaddableGroupDisabled,
  };
}
