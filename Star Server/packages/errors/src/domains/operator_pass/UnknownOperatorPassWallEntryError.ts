// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {NotFoundError} from '@star/errors/src/domains/core/NotFoundError';

export class UnknownOperatorPassWallEntryError extends NotFoundError {
	constructor() {
		super({code: APIErrorCodes.UNKNOWN_OPERATOR_PASS_WALL_ENTRY});
	}
}
