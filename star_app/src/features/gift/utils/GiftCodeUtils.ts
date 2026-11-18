// SPDX-License-Identifier: AGPL-3.0-or-later

import RuntimeConfig from '@app/features/app/state/RuntimeConfig';
import * as CodeLinkUtils from '@app/features/messaging/utils/CodeLinkUtils';

const OFFICIAL_GIFT_URL_BASES = Object.freeze([
	'https://app.star.example/gift',
	'https://canary.app.star.example/gift',
	'https://web.app.star.example/gift',
	'https://web.canary.app.star.example/gift',
	'https://star.example/gift',
	'https://canary.star.example/gift',
	'https://gift.star.example',
	'https://gift.star.example/gift',
]);
const GIFT_CONFIG: CodeLinkUtils.CodeLinkConfig = {
	path: 'gift',
	get urlBases() {
		if (RuntimeConfig.isSelfHosted()) {
			return [RuntimeConfig.giftUrlBase];
		}
		return [RuntimeConfig.giftUrlBase, ...OFFICIAL_GIFT_URL_BASES];
	},
};

export function findGifts(content: string | null): Array<string> {
	return CodeLinkUtils.findCodes(content, GIFT_CONFIG);
}

export function findSpoileredGifts(content: string | null): Array<CodeLinkUtils.CodeLinkMatch> {
	return CodeLinkUtils.findSpoileredCodeMatches(content, GIFT_CONFIG);
}
