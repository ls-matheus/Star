// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {defaultCodeStatusError} from '@star/errors/src/StarError';

export class UnauthorizedError extends defaultCodeStatusError(401, APIErrorCodes.UNAUTHORIZED) {}
