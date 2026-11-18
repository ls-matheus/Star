// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {StarError} from '@star/errors/src/StarError';

export class SearchIndexNotReadyError extends StarError {
	constructor(retryAfterSeconds: number) {
		super({
			code: APIErrorCodes.SEARCH_INDEX_NOT_READY,
			status: 202,
			data: {
				documents_indexed: 0,
				retry_after: retryAfterSeconds,
			},
		});
	}
}
