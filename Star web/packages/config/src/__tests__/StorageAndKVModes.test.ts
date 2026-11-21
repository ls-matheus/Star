// SPDX-License-Identifier: AGPL-3.0-or-later

import {readFileSync} from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadConfig, parseUploadsTtlMs, resetConfig} from '@star/config/src/ConfigLoader';
import {afterEach, beforeEach, describe, expect, test, vi} from 'vitest';

const VECTORS_PATH = path.resolve(
	path.dirname(fileURLToPath(import.meta.url)),
	'../../../../star_common/src/testdata/filesystem_storage_vectors.json',
);

const uploadsTtl = (
	JSON.parse(readFileSync(VECTORS_PATH, 'utf8')) as {
		uploads_ttl: {valid: Array<string>; invalid: Array<string>};
	}
).uploads_ttl;

const DAY_MS = 86_400_000;

const BASE_ENV: Record<string, string> = {
	STAR_ENV: 'test',
	STAR_BASE_DOMAIN: 'localhost',
	STAR_MEDIA_PROXY_SECRET_KEY: 'test-media-secret',
	STAR_MEDIA_PROXY_UPLOAD_RELAY_SECRET_BASE64: 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
	STAR_ADMIN_SECRET_KEY_BASE: 'test-admin-secret',
	STAR_ADMIN_OAUTH_CLIENT_SECRET: 'test-admin-oauth-secret',
	STAR_GATEWAY_RPC_AUTH_TOKEN: 'test-gateway-token',
	STAR_SUDO_MODE_SECRET: 'test-sudo-secret',
	STAR_CONNECTION_INITIATION_SECRET: 'test-connection-secret',
	STAR_PROFILE_PSEUDONYM_SECRET: 'test-profile-pseudonym-secret',
	STAR_VAPID_PUBLIC_KEY: 'BB76bTFIuoqmxJtTfZX0yGTn1f_qu9H03B_nkj8OyExJFkN7Y-HBZZzShnHZoEhXKc5ZRy3jFu7OkBbnaQG-4aw',
	STAR_VAPID_PRIVATE_KEY: 'Xgi-3P8J-I3Q6U1HlCcXMuc_tKLGAM9nIfznX3Hz68o',
};

function stubEnv(overrides: Record<string, string>): void {
	for (const key of Object.keys(process.env)) {
		if (key.startsWith('STAR_')) {
			vi.stubEnv(key, undefined);
		}
	}
	for (const [key, value] of Object.entries({...BASE_ENV, ...overrides})) {
		vi.stubEnv(key, value);
	}
}

describe('uploads TTL grammar', () => {
	test('accepts every shared valid value and rejects every shared invalid one', () => {
		for (const value of uploadsTtl.valid) {
			expect(() => parseUploadsTtlMs(value), value).not.toThrow();
		}
		for (const value of uploadsTtl.invalid) {
			expect(() => parseUploadsTtlMs(value), JSON.stringify(value)).toThrow('STAR_STORAGE_UPLOADS_TTL');
		}
	});

	test('uses the SeaweedFS unit lengths and treats a zero count as off', () => {
		expect(parseUploadsTtlMs('30m')).toBe(30 * 60_000);
		expect(parseUploadsTtlMs('2w')).toBe(14 * DAY_MS);
		expect(parseUploadsTtlMs('1M')).toBe(30 * DAY_MS);
		expect(parseUploadsTtlMs('1y')).toBe(365 * DAY_MS);
		expect(parseUploadsTtlMs('0d')).toBeNull();
		expect(parseUploadsTtlMs('off')).toBeNull();
	});
});

describe('storage and key-value modes', () => {
	beforeEach(() => resetConfig());
	afterEach(() => {
		resetConfig();
		vi.unstubAllEnvs();
	});

	test('filesystem mode starts without S3 credentials and reads the SeaweedFS TTL as a fallback', async () => {
		stubEnv({
			STAR_STORAGE_BACKEND: 'filesystem',
			STAR_STORAGE_ROOT: '/var/lib/star/objects',
			STAR_SEAWEEDFS_UPLOADS_TTL: '12h',
		});
		const config = await loadConfig();
		expect(config.storage).toEqual({
			backend: 'filesystem',
			root: '/var/lib/star/objects',
			uploads_ttl: '12h',
			read_only: false,
		});
	});

	test('filesystem mode needs an absolute root and a valid TTL', async () => {
		stubEnv({STAR_STORAGE_BACKEND: 'filesystem'});
		await expect(loadConfig()).rejects.toThrow('STAR_STORAGE_ROOT is required');
		resetConfig();
		stubEnv({STAR_STORAGE_BACKEND: 'filesystem', STAR_STORAGE_ROOT: 'objects'});
		await expect(loadConfig()).rejects.toThrow('STAR_STORAGE_ROOT must be an absolute path');
		resetConfig();
		stubEnv({
			STAR_STORAGE_BACKEND: 'filesystem',
			STAR_STORAGE_ROOT: '/srv/objects',
			STAR_SEAWEEDFS_UPLOADS_TTL: '30',
		});
		await expect(loadConfig()).rejects.toThrow('STAR_STORAGE_UPLOADS_TTL must be');
	});

	test('s3 mode still requires the S3 credentials', async () => {
		stubEnv({});
		await expect(loadConfig()).rejects.toThrow('STAR_S3_ACCESS_KEY_ID is required');
	});

	test('postgres key-value mode needs the postgres database backend', async () => {
		stubEnv({
			STAR_STORAGE_BACKEND: 'filesystem',
			STAR_STORAGE_ROOT: '/srv/objects',
			STAR_KV_MODE: 'postgres',
			STAR_KV_POSTGRES_MAX_CONNECTIONS: '6',
		});
		expect((await loadConfig()).internal.kv_postgres).toEqual({max_connections: 6});
		resetConfig();
		stubEnv({
			STAR_STORAGE_BACKEND: 'filesystem',
			STAR_STORAGE_ROOT: '/srv/objects',
			STAR_KV_MODE: 'postgres',
			STAR_DATABASE_BACKEND: 'cassandra',
		});
		await expect(loadConfig()).rejects.toThrow('STAR_DATABASE_BACKEND must be postgres');
	});
});
