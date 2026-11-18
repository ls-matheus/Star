// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {ForbiddenError} from '@star/errors/src/domains/core/ForbiddenError';
import type {EnforcementNotice} from '@star/schema/src/domains/auth/EnforcementNoticeSchemas';

export class AccountTemporarilySuspendedError extends ForbiddenError {
	constructor(notice: EnforcementNotice) {
		super({code: APIErrorCodes.ACCOUNT_SUSPENDED_TEMPORARILY, data: {notice}});
	}
}
