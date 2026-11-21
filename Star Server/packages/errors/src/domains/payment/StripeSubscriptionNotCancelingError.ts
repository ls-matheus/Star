// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {StarError} from '@star/errors/src/StarError';

export class StripeSubscriptionNotCancelingError extends StarError {
	constructor() {
		super({
			code: APIErrorCodes.STRIPE_SUBSCRIPTION_NOT_CANCELING,
			status: 400,
		});
	}
}
