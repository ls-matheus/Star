// SPDX-License-Identifier: AGPL-3.0-or-later

import {statusError} from '@star/errors/src/StarError';

export class BadRequestError extends statusError(400) {}
