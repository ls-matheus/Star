// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {StarError} from '@star/errors/src/StarError';

export class StripeInvalidProductError extends StarError {
	constructor() {
		super({
			code: APIErrorCodes.STRIPE_INVALID_PRODUCT,
			status: 400,
		});
	}
}
