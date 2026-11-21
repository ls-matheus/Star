// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {BadRequestError} from '@star/errors/src/domains/core/BadRequestError';

export class PersonalNotesDisabledError extends BadRequestError {
	constructor() {
		super({code: APIErrorCodes.PERSONAL_NOTES_DISABLED});
	}
}
