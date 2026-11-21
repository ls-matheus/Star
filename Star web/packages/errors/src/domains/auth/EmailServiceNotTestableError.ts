// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {InternalServerError} from '@star/errors/src/domains/core/InternalServerError';

export class EmailServiceNotTestableError extends InternalServerError {
	constructor() {
		super({code: APIErrorCodes.EMAIL_SERVICE_NOT_TESTABLE});
	}
}
