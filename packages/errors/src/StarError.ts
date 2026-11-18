// SPDX-License-Identifier: AGPL-3.0-or-later

import type {APIErrorCode} from '@star/constants/src/ApiErrorCodes';
import type {ErrorResponse} from '@star/schema/src/domains/common/ErrorSchemas';
import {HTTPException} from 'hono/http-exception';

export type StarErrorData = Record<string, unknown>;
export type StarErrorStatus = HTTPException['status'];

interface StarErrorOptions {
	code: string;
	message?: string;
	status: StarErrorStatus;
	data?: StarErrorData;
	headers?: Record<string, string>;
	messageVariables?: Record<string, unknown>;
	cause?: Error;
}

export class StarError extends HTTPException {
	readonly code: string;
	override readonly message: string;
	override readonly status: StarErrorStatus;
	readonly data?: StarErrorData;
	readonly headers?: Record<string, string>;
	readonly messageVariables?: Record<string, unknown>;

	constructor(options: StarErrorOptions) {
		const resolvedMessage = options.message ?? options.code;
		super(options.status, {message: resolvedMessage, cause: options.cause});
		this.code = options.code;
		this.message = resolvedMessage;
		this.status = options.status;
		this.data = options.data;
		this.headers = options.headers;
		this.messageVariables = options.messageVariables;
		this.name = 'StarError';
	}

	override getResponse(): Response {
		return new Response(JSON.stringify(this.toJSON()), {
			status: this.status,
			headers: {
				'Content-Type': 'application/json',
				...this.headers,
			},
		});
	}

	toJSON(): ErrorResponse {
		return {
			code: this.code,
			message: this.message,
			...this.data,
		};
	}
}

type StatusErrorOptions = Omit<StarErrorOptions, 'status' | 'code'>;
type RequiredStatusErrorOptions<TAllowMessage extends boolean> = {code: APIErrorCode} & (TAllowMessage extends true
	? StatusErrorOptions
	: Omit<StatusErrorOptions, 'message'>);

export function statusError<TAllowMessage extends boolean = true>(
	status: StarErrorStatus,
	allowMessage: TAllowMessage = true as TAllowMessage,
) {
	return class extends StarError {
		constructor(options: RequiredStatusErrorOptions<TAllowMessage>) {
			const {message, ...rest} = options as StatusErrorOptions & {code: APIErrorCode};
			super({...rest, status, message: allowMessage ? message : undefined});
		}
	};
}

export function defaultCodeStatusError<TCode extends string = APIErrorCode>(
	status: StarErrorStatus,
	defaultCode: NoInfer<TCode>,
) {
	return class extends StarError {
		constructor({code = defaultCode, ...options}: StatusErrorOptions & {code?: TCode} = {}) {
			super({...options, code, status});
		}
	};
}
