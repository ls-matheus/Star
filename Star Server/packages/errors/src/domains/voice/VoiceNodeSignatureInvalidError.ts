// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {UnauthorizedError} from '@star/errors/src/domains/core/UnauthorizedError';

export class VoiceNodeSignatureInvalidError extends UnauthorizedError {
	constructor() {
		super({code: APIErrorCodes.VOICE_NODE_SIGNATURE_INVALID});
	}
}
