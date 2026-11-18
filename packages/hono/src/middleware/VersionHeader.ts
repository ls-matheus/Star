// SPDX-License-Identifier: AGPL-3.0-or-later

import {Headers as HttpHeaders} from '@star/constants/src/Headers';
import type {MiddlewareHandler} from 'hono';

function resolveStarVersion(): string {
	const value = process.env.BUILD_VERSION?.trim();
	return value && value.length > 0 ? value : 'dev';
}

export function applyStarVersionHeader(response: Response, version = resolveStarVersion()): Response {
	const headers = new Headers(response.headers);
	headers.set(HttpHeaders.X_STAR_VERSION, version);
	return new Response(response.body, {
		status: response.status,
		statusText: response.statusText,
		headers,
	});
}

export function starVersionHeader(version = resolveStarVersion()): MiddlewareHandler {
	return async (c, next) => {
		await next();
		c.res.headers.set(HttpHeaders.X_STAR_VERSION, version);
	};
}
