// SPDX-License-Identifier: AGPL-3.0-or-later

export interface StarButtonBadgeCountInput {
	incomingFriendRequestCount: number;
	inlineDmsCollapsed: boolean;
	showCollapsedUnreadDmsBadge: boolean;
	showIncomingFriendRequestBadge: boolean;
	unreadDmCount: number;
}

export function getStarButtonBadgeCount({
	incomingFriendRequestCount,
	inlineDmsCollapsed,
	showCollapsedUnreadDmsBadge,
	showIncomingFriendRequestBadge,
	unreadDmCount,
}: StarButtonBadgeCountInput): number {
	let count = 0;
	if (inlineDmsCollapsed && showCollapsedUnreadDmsBadge) {
		count += unreadDmCount;
	}
	if (showIncomingFriendRequestBadge) {
		count += incomingFriendRequestCount;
	}
	return count;
}
