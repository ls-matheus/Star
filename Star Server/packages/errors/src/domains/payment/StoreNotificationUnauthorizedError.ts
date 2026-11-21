// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {StarError} from '@star/errors/src/StarError';

export class StoreNotificationUnauthorizedError extends StarError {
	constructor() {
		super({
			code: APIErrorCodes.STORE_NOTIFICATION_UNAUTHORIZED,
			status: 401,
		});
	}
}
