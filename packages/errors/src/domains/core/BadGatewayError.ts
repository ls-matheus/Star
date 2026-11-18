// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {defaultCodeStatusError} from '@star/errors/src/StarError';

export class BadGatewayError extends defaultCodeStatusError(502, APIErrorCodes.BAD_GATEWAY) {}
