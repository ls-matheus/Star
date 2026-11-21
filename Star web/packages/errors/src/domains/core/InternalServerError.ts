// SPDX-License-Identifier: AGPL-3.0-or-later

import {statusError} from '@star/errors/src/StarError';

export class InternalServerError extends statusError(500, false) {}
