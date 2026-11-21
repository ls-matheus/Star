// SPDX-License-Identifier: AGPL-3.0-or-later

import {generateKeyPairSync} from 'node:crypto';
import {existsSync} from 'node:fs';
import type {UserID} from '@app/api/BrandedTypes';
import {buildAPIConfigFromMaster, initializeConfig} from '@app/api/Config';
import {setInjectedMessageResponseDataService} from '@app/api/channel/services/message/MessageResponseDataService';
import type {APIConfig} from '@app/api/config/APIConfig';
import {
	resetCassandraQueryExecutorForTesting,
	setCassandraQueryExecutorForTesting,
	shutdownCassandraQueryExecutorForTesting,
} from '@app/api/database/CassandraQueryExecution';
import type {
	AppAttestAgeAccepted,
	AppAttestChallengeIssued,
	AppAttestOutcome,
	IUsersServiceClient,
	PlayIntegrityOutcome,
} from '@app/api/infrastructure/UsersServiceClient';
import {setInjectedUsersServiceClient} from '@app/api/infrastructure/UsersServiceClient';
import {initializeLogger} from '@app/api/Logger';
import {setInjectedKVProvider, setInjectedSnowflakeService} from '@app/api/middleware/ServiceRegistry';
import {getInstanceConfigRepository, getUserRepository} from '@app/api/middleware/ServiceSingletons';
import {drainSearchTasks, enableSearchTaskTracking} from '@app/api/search/SearchTaskTracker';
import {InMemoryCassandraQueryExecutor} from '@app/api/test/InMemoryCassandraQueryExecutor';
import {MockSnowflakeService} from '@app/api/test/mocks/MockSnowflakeService';
import {NoopLogger} from '@app/api/test/mocks/NoopLogger';
import {RepositoryBackedMessageResponseDataService} from '@app/api/test/mocks/RepositoryBackedMessageResponseDataService';
import {server} from '@app/api/test/msw/server';
import {mapUserToPartialResponse} from '@app/api/user/UserMappers';
import {loadConfig} from '@star/config/src/ConfigLoader';
import type {UserPartialResponse} from '@star/schema/src/domains/user/UserResponseSchemas';
import {MockKVProvider} from '@pkgs/kv_client/src/testing/MockKVProvider';
import {afterAll, afterEach, beforeAll} from 'vitest';

function defaultNatsUrl(): string {
	return `nats://${existsSync('/.dockerenv') ? 'nats' : '127.0.0.1'}:4222`;
}

function setDefaultTestEnv(): void {
	// API tests use a non-self-hosted baseline; self-hosted scenarios override the loaded config explicitly.
	process.env.STAR_SELF_HOSTED = 'false';

	const natsUrl = defaultNatsUrl();
	const defaults: Record<string, string> = {
		STAR_ENV: 'test',
		STAR_BASE_DOMAIN: 'localhost',
		STAR_PUBLIC_SCHEME: 'http',
		STAR_PUBLIC_PORT: '8088',
		STAR_TRUST_CLIENT_IP_HEADER: 'true',
		STAR_CLIENT_IP_HEADER_NAME: 'x-forwarded-for',
		STAR_CASSANDRA_HOSTS: '127.0.0.1',
		STAR_CASSANDRA_PORT: '9042',
		STAR_CASSANDRA_KEYSPACE: 'star_test',
		STAR_CASSANDRA_LOCAL_DC: 'datacenter1',
		STAR_CASSANDRA_USERNAME: 'cassandra',
		STAR_CASSANDRA_PASSWORD: 'cassandra',
		STAR_KV_URL: 'redis://127.0.0.1:6379/0',
		STAR_NATS_URL: natsUrl,
		STAR_NATS_CORE_URL: natsUrl,
		STAR_NATS_JETSTREAM_URL: natsUrl,
		STAR_INTERNAL_MEDIA_PROXY_ENDPOINT: 'http://127.0.0.1:8088/media',
		STAR_S3_ENDPOINT: 'http://127.0.0.1:3900',
		STAR_S3_REGION: 'local',
		STAR_S3_ACCESS_KEY_ID: 'test',
		STAR_S3_SECRET_ACCESS_KEY: 'test',
		STAR_API_PRESIGNED_ATTACHMENT_UPLOADS_ENABLED: 'false',
		STAR_MEDIA_PROXY_SECRET_KEY: 'test-media-secret',
		STAR_MEDIA_PROXY_ATTACHMENT_URL_SECRETS_BASE64: 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
		STAR_ADMIN_SECRET_KEY_BASE: 'test-admin-secret',
		STAR_ADMIN_OAUTH_CLIENT_SECRET: 'test-admin-oauth-secret',
		STAR_ADMIN_SSO_ISSUER: 'https://1.1.1.1/admin-sso',
		STAR_ADMIN_SSO_CLIENT_ID: 'admin-sso-test-client',
		STAR_GATEWAY_RPC_AUTH_TOKEN: 'test-gateway-rpc-token',
		STAR_SUDO_MODE_SECRET: 'test-sudo-secret',
		STAR_CONNECTION_INITIATION_SECRET: 'test-connection-secret',
		STAR_VAPID_PUBLIC_KEY: 'BB76bTFIuoqmxJtTfZX0yGTn1f_qu9H03B_nkj8OyExJFkN7Y-HBZZzShnHZoEhXKc5ZRy3jFu7OkBbnaQG-4aw',
		STAR_VAPID_PRIVATE_KEY: 'Xgi-3P8J-I3Q6U1HlCcXMuc_tKLGAM9nIfznX3Hz68o',
		STAR_VAPID_EMAIL: 'test@example.com',
		STAR_PASSKEY_RP_NAME: 'Star Test',
		STAR_PASSKEY_RP_ID: 'localhost',
		STAR_PASSKEY_ADDITIONAL_ALLOWED_ORIGINS: 'http://localhost',
		STAR_EMAIL_ENABLED: 'true',
		STAR_EMAIL_PROVIDER: 'smtp',
		STAR_EMAIL_FROM_EMAIL: 'noreply@example.com',
		STAR_EMAIL_SMTP_HOST: 'localhost',
		STAR_EMAIL_SMTP_PORT: '1025',
		STAR_EMAIL_SMTP_USERNAME: 'test',
		STAR_EMAIL_SMTP_PASSWORD: 'test',
		STAR_EMAIL_SMTP_TLS_MODE: 'none',
		STAR_LIVEKIT_ENABLED: 'false',
		STAR_STRIPE_ENABLED: 'true',
		STAR_SEARCH_ENGINE: 'elasticsearch',
		STAR_SEARCH_URL: 'http://127.0.0.1:9200',
		STAR_SEARCH_API_KEY: 'test',
		STAR_DISCOVERY_ENABLED: 'true',
		STAR_RELAX_REGISTRATION_RATE_LIMITS: 'true',
		STAR_DISABLE_RATE_LIMITS: 'true',
		STAR_TEST_MODE_ENABLED: 'true',
	};
	for (const [key, value] of Object.entries(defaults)) {
		process.env[key] ??= value;
	}
}

class RepositoryBackedUsersServiceClient implements IUsersServiceClient {
	async getUserPartialResponses(userIds: Array<UserID>): Promise<Map<UserID, UserPartialResponse>> {
		const userRepository = getUserRepository();
		const result = new Map<UserID, UserPartialResponse>();
		for (const userId of userIds) {
			const user = await userRepository.findUnique(userId);
			if (user) {
				result.set(userId, mapUserToPartialResponse(user));
			}
		}
		return result;
	}

	async invalidateUserCache(_userId: UserID): Promise<void> {}

	async appAttestCreateChallenge(): Promise<AppAttestOutcome<AppAttestChallengeIssued>> {
		return {ok: false, code: 'not_configured'};
	}

	async appAttestRegisterKey(): Promise<AppAttestOutcome<true>> {
		return {ok: false, code: 'not_configured'};
	}

	async appAttestSubmitAge(): Promise<AppAttestOutcome<AppAttestAgeAccepted>> {
		return {ok: false, code: 'not_configured'};
	}

	async playIntegrityCreateChallenge(): Promise<PlayIntegrityOutcome<AppAttestChallengeIssued>> {
		return {ok: false, code: 'not_configured'};
	}

	async playIntegritySubmitAge(): Promise<PlayIntegrityOutcome<AppAttestAgeAccepted>> {
		return {ok: false, code: 'not_configured'};
	}
}

setDefaultTestEnv();
process.env.STAR_MEDIA_PROXY_UPLOAD_RELAY_SECRET_BASE64 ??= 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=';

function generateTestPrivateKeyPem(type: 'ec' | 'rsa'): string {
	const {privateKey} =
		type === 'ec'
			? generateKeyPairSync('ec', {namedCurve: 'prime256v1'})
			: generateKeyPairSync('rsa', {modulusLength: 2048});
	return privateKey.export({format: 'pem', type: 'pkcs8'}).toString();
}

const master = await loadConfig();
const apiConfig = buildAPIConfigFromMaster(master);
const testApiConfig: APIConfig = {
	...apiConfig,
	auth: {
		...apiConfig.auth,
		passkeys: {
			...apiConfig.auth.passkeys,
			rpId: 'localhost',
			allowedOrigins: ['http://localhost'],
		},
	},
	voice: {
		...apiConfig.voice,
		enabled: false,
	},
	stripe: {
		...apiConfig.stripe,
		enabled: true,
		secretKey: 'sk_test_star',
		webhookSecret: 'whsec_test_star',
	},
	appStore: {
		...apiConfig.appStore,
		enabled: true,
		issuerId: '57246542-96fe-1a63-e053-0824d011072a',
		keyId: 'STARTEST',
		privateKey: generateTestPrivateKeyPem('ec'),
		privateKeyPath: undefined,
		apps: [{bundleId: 'com.star', appAppleId: 1234567890}],
		products: {
			'com.star.plutonium.monthly': 'monthly',
			'com.star.plutonium.yearly': 'yearly',
			'com.star.gift.1month': 'gift_1_month',
			'com.star.gift.1year': 'gift_1_year',
		},
	},
	googlePlay: {
		...apiConfig.googlePlay,
		enabled: true,
		packages: ['com.star'],
		clientEmail: 'play-billing@star-test.iam.gserviceaccount.com',
		privateKey: generateTestPrivateKeyPem('rsa'),
		privateKeyPath: undefined,
		serviceAccountJsonPath: undefined,
		tokenUri: 'https://oauth2.googleapis.com/token',
		products: {
			'plutonium:monthly': 'monthly',
			'plutonium:yearly': 'yearly',
			gift_1_month: 'gift_1_month',
			gift_1_year: 'gift_1_year',
		},
		pushAudience: 'https://api.star.test/webhooks/google-play',
		pushServiceAccountEmail: 'rtdn@star-test.iam.gserviceaccount.com',
	},
	storeBilling: {
		sandboxUserIds: [],
		sandboxEntitlesAll: false,
		sandboxSubscriptions: false,
	},
};
testApiConfig.dev.relaxRegistrationRateLimits = true;
testApiConfig.dev.disableRateLimits = true;
testApiConfig.dev.testModeEnabled = true;

initializeConfig(testApiConfig);

const bootstrapLogger = new NoopLogger();

initializeLogger(bootstrapLogger);

setCassandraQueryExecutorForTesting(new InMemoryCassandraQueryExecutor());

setInjectedKVProvider(new MockKVProvider());
setInjectedSnowflakeService(new MockSnowflakeService({startTimestampMs: Date.now()}));
setInjectedUsersServiceClient(new RepositoryBackedUsersServiceClient());
setInjectedMessageResponseDataService(new RepositoryBackedMessageResponseDataService());

enableSearchTaskTracking();

beforeAll(async () => {
	server.listen({
		onUnhandledRequest: 'error',
	});
});

afterEach(async () => {
	await drainSearchTasks();
	resetCassandraQueryExecutorForTesting();
	getInstanceConfigRepository().clearCacheForTesting();
	server.resetHandlers();
});

afterAll(async () => {
	server.close();
	await shutdownCassandraQueryExecutorForTesting();
});
