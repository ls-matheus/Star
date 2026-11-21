// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {BadRequestError} from '@star/errors/src/domains/core/BadRequestError';
import type {StarErrorData} from '@star/errors/src/StarError';

export class CaptchaRequiredError extends BadRequestError {
	constructor(data?: StarErrorData) {
		super({code: APIErrorCodes.CAPTCHA_REQUIRED, data});
		this.name = 'CaptchaRequiredError';
	}
}

export class InvalidCaptchaError extends BadRequestError {
	constructor(data?: StarErrorData) {
		super({code: APIErrorCodes.INVALID_CAPTCHA, data});
		this.name = 'InvalidCaptchaError';
	}
}
