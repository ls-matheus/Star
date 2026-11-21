// SPDX-License-Identifier: AGPL-3.0-or-later

import type {
	AccountVerificationNeed,
	RestrictedAccountTier,
	TierGatedAction,
} from '@star/constants/src/AccountTierConstants';
import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {ForbiddenError} from '@star/errors/src/domains/core/ForbiddenError';

export class AccountVerificationRequiredError extends ForbiddenError {
	constructor(action: TierGatedAction, tier: RestrictedAccountTier, need: AccountVerificationNeed) {
		super({
			code: APIErrorCodes.ACCOUNT_VERIFICATION_REQUIRED,
			data: {action, tier, need},
			messageVariables: {action, need},
		});
	}
}
