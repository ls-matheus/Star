// SPDX-License-Identifier: AGPL-3.0-or-later
// Star Dev is an isolated, client-only workspace. It does not authenticate or call the Star API.

export const DEV_SESSION_ACTIVE_KEY = 'star.dev.active.v1';
export const DEV_SESSION_DATA_KEY = 'star.dev.workspace.v1';

export interface DevChannel {
	id: string;
	name: string;
	topic: string;
}

export interface DevCommunity {
	id: string;
	name: string;
	channels: Array<DevChannel>;
}

export interface DevMessage {
	id: string;
	channelId: string;
	body: string;
	author: string;
	createdAt: number;
	edited: boolean;
	liked: boolean;
}

export interface DevWorkspaceState {
	version: 1;
	communities: Array<DevCommunity>;
	messages: Array<DevMessage>;
	selectedCommunityId: string | null;
	selectedChannelId: string | null;
	displayName: string;
	drafts: Record<string, string>;
}

function storage(): Storage | null {
	if (typeof window === 'undefined') return null;
	try {
		return window.sessionStorage;
	} catch {
		return null;
	}
}

export function freshDevWorkspace(): DevWorkspaceState {
	const now = Date.now();
	return {
		version: 1,
		communities: [
			{
				id: 'dev-home',
				name: 'Star Dev',
				channels: [
					{id: 'dev-general', name: 'geral', topic: 'Converse e experimente sem usar um servidor.'},
					{id: 'dev-projects', name: 'projetos', topic: 'Planeje e teste suas ideias.'},
				],
			},
		],
		messages: [
			{
				id: 'dev-welcome',
				channelId: 'dev-general',
				author: 'Star Dev',
				body: 'Bem-vindo ao modo Dev! Crie comunidades, canais e mensagens. Tudo fica apenas nesta sessão, sem conexão com servidores reais.',
				createdAt: now,
				edited: false,
				liked: false,
			},
		],
		selectedCommunityId: 'dev-home',
		selectedChannelId: 'dev-general',
		displayName: 'Desenvolvedor',
		drafts: {},
	};
}

function validWorkspace(value: unknown): value is DevWorkspaceState {
	if (value == null || typeof value !== 'object') return false;
	const state = value as Partial<DevWorkspaceState>;
	return (
		state.version === 1 &&
		Array.isArray(state.communities) &&
		Array.isArray(state.messages) &&
		typeof state.displayName === 'string' &&
		typeof state.drafts === 'object' &&
		state.drafts != null &&
		(state.selectedCommunityId === null || typeof state.selectedCommunityId === 'string') &&
		(state.selectedChannelId === null || typeof state.selectedChannelId === 'string') &&
		state.communities.every(
			(community) =>
				community != null &&
				typeof community.id === 'string' &&
				typeof community.name === 'string' &&
				Array.isArray(community.channels) &&
				community.channels.every(
					(channel) =>
						channel != null &&
						typeof channel.id === 'string' &&
						typeof channel.name === 'string' &&
						typeof channel.topic === 'string',
				),
		) &&
		state.messages.every(
			(message) =>
				message != null &&
				typeof message.id === 'string' &&
				typeof message.channelId === 'string' &&
				typeof message.body === 'string' &&
				typeof message.author === 'string' &&
				typeof message.createdAt === 'number' &&
				typeof message.edited === 'boolean' &&
				typeof message.liked === 'boolean',
		)
	);
}

export function loadDevWorkspace(): DevWorkspaceState {
	try {
		const saved = storage()?.getItem(DEV_SESSION_DATA_KEY);
		if (saved != null) {
			const parsed: unknown = JSON.parse(saved);
			if (validWorkspace(parsed)) return parsed;
		}
	} catch {
		// Invalid or unavailable storage never blocks use of the ephemeral workspace.
	}
	return freshDevWorkspace();
}

export function saveDevWorkspace(state: DevWorkspaceState): boolean {
	try {
		const target = storage();
		if (target == null) return false;
		target.setItem(DEV_SESSION_DATA_KEY, JSON.stringify(state));
		return true;
	} catch {
		// Quota errors leave in-memory editing available until the view is closed.
		return false;
	}
}

function isStoredDevSessionActive(): boolean {
	try {
		return storage()?.getItem(DEV_SESSION_ACTIVE_KEY) === '1';
	} catch {
		return false;
	}
}

let active = isStoredDevSessionActive();
const listeners = new Set<() => void>();

export function getDevSessionActive(): boolean {
	return active;
}

export function subscribeDevSession(listener: () => void): () => void {
	listeners.add(listener);
	return () => listeners.delete(listener);
}

function notify(): void {
	for (const listener of listeners) listener();
}

export function enterDevSession(): void {
	active = true;
	try {
		storage()?.setItem(DEV_SESSION_ACTIVE_KEY, '1');
	} catch {
		// In-memory session remains available if browser storage is disabled.
	}
	notify();
}

export function leaveDevSession(): void {
	active = false;
	try {
		const target = storage();
		target?.removeItem(DEV_SESSION_ACTIVE_KEY);
		target?.removeItem(DEV_SESSION_DATA_KEY);
	} catch {
		// Ending the session must still exit the local workspace.
	}
	notify();
}
