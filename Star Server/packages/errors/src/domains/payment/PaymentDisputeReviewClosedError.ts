// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {ConflictError} from '@star/errors/src/domains/core/ConflictError';

export class PaymentDisputeReviewClosedError extends ConflictError {
	constructor() {
		super({code: APIErrorCodes.PAYMENT_DISPUTE_REVIEW_CLOSED});
	}
}
