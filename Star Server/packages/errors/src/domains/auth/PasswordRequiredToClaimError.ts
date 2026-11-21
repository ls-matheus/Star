// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import type {ValueOf} from '@star/constants/src/ValueOf';
import {BadRequestError} from '@star/errors/src/domains/core/BadRequestError';

export const PasswordRequiredToClaimReasons = {
	USERNAME_IDENTITY: 'username_identity',
	EMAIL_DELIVERY_OFF: 'email_delivery_off',
	LOCAL_CREDENTIAL_BASIS: 'local_credential_basis',
} as const;

export type PasswordRequiredToClaimReason = ValueOf<typeof PasswordRequiredToClaimReasons>;

export class PasswordRequiredToClaimError extends BadRequestError {
	constructor(reason: PasswordRequiredToClaimReason) {
		super({code: APIErrorCodes.PASSWORD_REQUIRED_TO_CLAIM, messageVariables: {reason}});
	}
}
