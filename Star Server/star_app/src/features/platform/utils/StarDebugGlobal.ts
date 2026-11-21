// SPDX-License-Identifier: AGPL-3.0-or-later

type StarDebugObject = NonNullable<Window['__STAR_DEBUG__']>;

export function getStarDebugObject(): StarDebugObject | null {
	if (typeof window === 'undefined') {
		return null;
	}
	const existing = window.__STAR_DEBUG__;
	if (existing === undefined || existing === null) {
		const created: StarDebugObject = {};
		window.__STAR_DEBUG__ = created;
		return created;
	}
	if (typeof existing !== 'object' || Array.isArray(existing)) {
		return null;
	}
	return existing;
}
