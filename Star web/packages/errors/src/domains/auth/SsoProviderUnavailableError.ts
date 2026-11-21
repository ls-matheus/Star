// SPDX-License-Identifier: AGPL-3.0-or-later

import {APIErrorCodes} from '@star/constants/src/ApiErrorCodes';
import {defaultCodeStatusError} from '@star/errors/src/StarError';

export class SsoProviderUnavailableError extends defaultCodeStatusError(503, APIErrorCodes.SSO_PROVIDER_UNAVAILABLE) {}
