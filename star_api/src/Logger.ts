// SPDX-License-Identifier: AGPL-3.0-or-later

import {createLogger, type Logger as StarLogger} from '@star/logger/src/Logger';

export const Logger = createLogger('star-api');

export type Logger = StarLogger;
