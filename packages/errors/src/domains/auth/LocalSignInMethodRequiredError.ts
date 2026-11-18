// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {ForbiddenError} from '@star/errors/src/domains/core/ForbiddenError';

export class LocalSignInMethodRequiredError extends ForbiddenError {
	constructor() {
		super({code: APIErrorCodes.LOCAL_SIGN_IN_METHOD_REQUIRED});
	}
}
