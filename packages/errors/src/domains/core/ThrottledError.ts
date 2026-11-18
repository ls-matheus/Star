// SPDX-License-Identifier: AGPL-3.0-or-later

import {sanitizeRetryAfterSeconds} from '@star/errors/src/domains/core/RetryAfterSeconds';
import {StarError, type StarErrorData} from '@star/errors/src/StarError';

export class ThrottledError extends StarError {
	constructor({
		code,
		message,
		retryAfterSeconds,
		data,
		headers,
		messageVariables,
	}: {
		code: string;
		message?: string;
		retryAfterSeconds: number;
		data?: StarErrorData;
		headers?: Record<string, string>;
		messageVariables?: Record<string, unknown>;
	}) {
		super({
			code,
			message,
			status: 429,
			data,
			headers: {...headers, 'Retry-After': sanitizeRetryAfterSeconds(retryAfterSeconds).toString()},
			messageVariables,
		});
	}
}
