// SPDX-License-Identifier: AGPL-3.0-or-later

import {readFileSync} from 'node:fs';
import {type ConfigObject, isConfigObject} from '@star/config/src/config_loader/ConfigObject';

type ConfigPathKey = string | number;
type ConfigContainer = ConfigObject | Array<unknown>;

type EnvValueParser = (raw: string) => unknown;

interface NamedEnvOverride {
	path: Array<ConfigPathKey>;
	parse?: EnvValueParser;
}

const NAMED_STAR_ENV_OVERRIDES: Record<string, NamedEnvOverride> = {
	STAR_ENV: {path: ['env']},
	STAR_BASE_DOMAIN: {path: ['domain', 'base_domain']},
	STAR_PUBLIC_ORIGIN: {path: ['domain', 'public_origin']},
	STAR_PUBLIC_SCHEME: {path: ['domain', 'public_scheme']},
	STAR_PUBLIC_PORT: {path: ['domain', 'public_port'], parse: parseInteger},
	STAR_STATIC_CDN_DOMAIN: {path: ['domain', 'static_cdn_domain']},
	STAR_INVITE_DOMAIN: {path: ['domain', 'invite_domain']},
	STAR_GIFT_DOMAIN: {path: ['domain', 'gift_domain']},
	STAR_API_ENDPOINT: {path: ['endpoint_overrides', 'api']},
	STAR_API_CLIENT_ENDPOINT: {path: ['endpoint_overrides', 'api_client']},
	STAR_APP_ENDPOINT: {path: ['endpoint_overrides', 'app']},
	STAR_GATEWAY_ENDPOINT: {path: ['endpoint_overrides', 'gateway']},
	STAR_MEDIA_ENDPOINT: {path: ['endpoint_overrides', 'media']},
	STAR_STATIC_CDN_ENDPOINT: {path: ['endpoint_overrides', 'static_cdn']},
	STAR_ADMIN_ENDPOINT: {path: ['endpoint_overrides', 'admin']},
	STAR_MARKETING_ENDPOINT: {path: ['endpoint_overrides', 'marketing']},
	STAR_INVITE_ENDPOINT: {path: ['endpoint_overrides', 'invite']},
	STAR_GIFT_ENDPOINT: {path: ['endpoint_overrides', 'gift']},
	STAR_TRUST_CLIENT_IP_HEADER: {path: ['proxy', 'trust_client_ip_header'], parse: parseBoolean},
	STAR_CLIENT_IP_HEADER_NAME: {path: ['proxy', 'client_ip_header']},
	STAR_CASSANDRA_HOSTS: {path: ['database', 'cassandra', 'hosts'], parse: parseCsv},
	STAR_CASSANDRA_PORT: {path: ['database', 'cassandra', 'port'], parse: parseInteger},
	STAR_CASSANDRA_KEYSPACE: {path: ['database', 'cassandra', 'keyspace']},
	STAR_CASSANDRA_LOCAL_DC: {path: ['database', 'cassandra', 'local_dc']},
	STAR_CASSANDRA_CONSISTENCY: {path: ['database', 'cassandra', 'consistency']},
	STAR_CASSANDRA_SERIAL_CONSISTENCY: {path: ['database', 'cassandra', 'serial_consistency']},
	STAR_CASSANDRA_USERNAME: {path: ['database', 'cassandra', 'username']},
	STAR_CASSANDRA_PASSWORD: {path: ['database', 'cassandra', 'password']},
	STAR_POSTGRES_URL: {path: ['database', 'postgres', 'url']},
	STAR_POSTGRES_HOST: {path: ['database', 'postgres', 'host']},
	STAR_POSTGRES_PORT: {path: ['database', 'postgres', 'port'], parse: parseInteger},
	STAR_POSTGRES_DATABASE: {path: ['database', 'postgres', 'database']},
	STAR_POSTGRES_USERNAME: {path: ['database', 'postgres', 'username']},
	STAR_POSTGRES_PASSWORD: {path: ['database', 'postgres', 'password']},
	STAR_POSTGRES_SSL: {path: ['database', 'postgres', 'ssl'], parse: parseBoolean},
	STAR_POSTGRES_SSL_CA: {path: ['database', 'postgres', 'ssl_ca']},
	STAR_POSTGRES_MAX_CONNECTIONS: {path: ['database', 'postgres', 'max_connections'], parse: parseInteger},
	STAR_POSTGRES_KV_TABLE: {path: ['database', 'postgres', 'kv_table']},
	STAR_POSTGRES_PREPARED_STATEMENTS: {path: ['database', 'postgres', 'prepared_statements'], parse: parseBoolean},
	STAR_DATABASE_BACKEND: {path: ['database', 'backend']},
	STAR_KV_URL: {path: ['internal', 'kv']},
	STAR_KV_MODE: {path: ['internal', 'kv_mode']},
	STAR_KV_POSTGRES_MAX_CONNECTIONS: {path: ['internal', 'kv_postgres', 'max_connections'], parse: parseInteger},
	STAR_KV_POSTGRES_MAX_BYTES: {path: ['internal', 'kv_postgres', 'max_bytes'], parse: parseInteger},
	STAR_STORAGE_BACKEND: {path: ['storage', 'backend']},
	STAR_STORAGE_ROOT: {path: ['storage', 'root']},
	STAR_STORAGE_UPLOADS_TTL: {path: ['storage', 'uploads_ttl']},
	STAR_STORAGE_READ_ONLY: {path: ['storage', 'read_only'], parse: parseBoolean},
	STAR_INTERNAL_MEDIA_PROXY_ENDPOINT: {path: ['internal', 'media_proxy']},
	STAR_S3_ENDPOINT: {path: ['s3', 'endpoint']},
	STAR_S3_PUBLIC_ENDPOINT: {path: ['s3', 'presigned_url_base']},
	STAR_S3_FORCE_PATH_STYLE: {path: ['s3', 'force_path_style'], parse: parseBoolean},
	STAR_S3_REGION: {path: ['s3', 'region']},
	STAR_S3_ACCESS_KEY_ID: {path: ['s3', 'access_key_id']},
	STAR_S3_SECRET_ACCESS_KEY: {path: ['s3', 'secret_access_key']},
	STAR_S3_BUCKET_CDN: {path: ['s3', 'buckets', 'cdn']},
	STAR_S3_BUCKET_UPLOADS: {path: ['s3', 'buckets', 'uploads']},
	STAR_S3_BUCKET_REPORTS: {path: ['s3', 'buckets', 'reports']},
	STAR_S3_BUCKET_HARVESTS: {path: ['s3', 'buckets', 'harvests']},
	STAR_NATS_URL: {path: ['services', 'nats', 'core_url']},
	STAR_NATS_JETSTREAM_URL: {path: ['services', 'nats', 'jetstream_url']},
	STAR_NATS_AUTH_TOKEN: {path: ['services', 'nats', 'auth_token']},
	STAR_API_PORT: {path: ['services', 'api', 'port'], parse: parseInteger},
	STAR_API_HOST: {path: ['services', 'api', 'host']},
	STAR_API_HEADERS_TIMEOUT_MS: {path: ['services', 'api', 'headers_timeout_ms'], parse: parseInteger},
	STAR_API_REQUEST_TIMEOUT_MS: {path: ['services', 'api', 'request_timeout_ms'], parse: parseInteger},
	STAR_API_MAX_INFLIGHT_REQUESTS: {path: ['services', 'api', 'max_inflight_requests'], parse: parseInteger},
	STAR_API_MAX_CONCURRENT_FORM_UPLOADS: {
		path: ['services', 'api', 'max_concurrent_form_uploads'],
		parse: parseInteger,
	},
	STAR_API_AUTOMATED_MESSAGE_DELETION_DELAY_DAYS: {
		path: ['services', 'api', 'automated_message_deletion_delay_days'],
		parse: parseInteger,
	},
	STAR_API_IP_BAN_EXEMPT_IPS: {path: ['services', 'api', 'ip_ban_exempt_ips'], parse: parseCsv},
	STAR_API_DONATION_PROXY_KEY: {path: ['services', 'api', 'donation_proxy_key']},
	STAR_API_TRUSTED_CALLERS: {path: ['services', 'api', 'trusted_callers'], parse: parseJsonArray},
	STAR_API_PRESIGNED_ATTACHMENT_UPLOADS_ENABLED: {
		path: ['services', 'api', 'presigned_attachment_uploads_enabled'],
		parse: parseBoolean,
	},
	STAR_API_PRESIGNED_HARVEST_DOWNLOADS_ENABLED: {
		path: ['services', 'api', 'presigned_harvest_downloads_enabled'],
		parse: parseBoolean,
	},
	STAR_API_WORKER_MODE: {path: ['services', 'api', 'worker', 'mode']},
	STAR_API_WORKER_LANE: {path: ['services', 'api', 'worker', 'lane']},
	STAR_API_WORKER_TASK: {path: ['services', 'api', 'worker', 'task']},
	STAR_API_WORKER_ENABLE_CRON_SCHEDULER: {
		path: ['services', 'api', 'worker', 'enable_cron_scheduler'],
		parse: parseBoolean,
	},
	STAR_API_WORKER_METRICS_PORT: {path: ['services', 'api', 'worker', 'metrics_port'], parse: parseInteger},
	STAR_API_EMBEDDED_WORKER: {path: ['services', 'api', 'worker', 'embedded'], parse: parseBoolean},
	STAR_API_WORKER_LANE_CONCURRENCY_OVERRIDES: {
		path: ['services', 'api', 'worker', 'lane_concurrency_overrides'],
		parse: parseJsonObject,
	},
	STAR_API_STORAGE_CHANGE_FEED_ENABLED: {
		path: ['services', 'api', 'storage_change_feed', 'enabled'],
		parse: parseBoolean,
	},
	STAR_API_STORAGE_CHANGE_FEED_STREAM: {path: ['services', 'api', 'storage_change_feed', 'stream']},
	STAR_API_STORAGE_CHANGE_FEED_SKIP_BUCKETS: {
		path: ['services', 'api', 'storage_change_feed', 'skip_buckets'],
		parse: parseBucketList,
	},
	STAR_API_UNFURL_IGNORED_HOSTS: {path: ['services', 'api', 'unfurl_ignored_hosts'], parse: parseCsv},
	STAR_APP_ORIGIN_ALIASES: {path: ['services', 'api', 'app_origin_aliases'], parse: parseCsv},
	STAR_API_DISCOVERY_PUBLIC_ENDPOINT: {path: ['services', 'api', 'discovery_public_endpoint']},
	STAR_API_DISCOVERY_TRANSPORT_ENDPOINT: {path: ['services', 'api', 'discovery_transport_endpoint']},
	STAR_MEDIA_PROXY_SECRET_KEY: {path: ['services', 'media_proxy', 'secret_key']},
	STAR_MEDIA_PROXY_UPLOAD_RELAY_ENDPOINT: {path: ['services', 'media_proxy', 'upload_relay', 'endpoint']},
	STAR_MEDIA_PROXY_UPLOAD_RELAY_SECRET_BASE64: {path: ['services', 'media_proxy', 'upload_relay', 'secret_base64']},
	STAR_MEDIA_PROXY_UPLOAD_RELAY_MAX_BODY_BYTES: {
		path: ['services', 'media_proxy', 'upload_relay', 'max_body_bytes'],
		parse: parseInteger,
	},
	STAR_MEDIA_PROXY_UPLOAD_RELAY_TOKEN_TTL_SECS: {
		path: ['services', 'media_proxy', 'upload_relay', 'token_ttl_secs'],
		parse: parseInteger,
	},
	STAR_MEDIA_PROXY_UPLOAD_RELAY_KEEP_DIRECT_COUNTRIES: {
		path: ['services', 'media_proxy', 'upload_relay', 'keep_direct_countries'],
		parse: parseCsv,
	},
	STAR_MEDIA_PROXY_ATTACHMENT_URL_SECRETS_BASE64: {
		path: ['services', 'media_proxy', 'attachment_urls', 'secrets_base64'],
		parse: parseCsv,
	},
	STAR_ADMIN_SECRET_KEY_BASE: {path: ['services', 'admin', 'secret_key_base']},
	STAR_ADMIN_OAUTH_CLIENT_SECRET: {path: ['services', 'admin', 'oauth_client_secret']},
	STAR_ADMIN_SSO_ISSUER: {path: ['services', 'admin', 'sso', 'issuer']},
	STAR_ADMIN_SSO_CLIENT_ID: {path: ['services', 'admin', 'sso', 'client_id']},
	STAR_GATEWAY_RPC_AUTH_TOKEN: {path: ['services', 'gateway', 'rpc_auth_token']},
	STAR_SUDO_MODE_SECRET: {path: ['auth', 'sudo_mode_secret']},
	STAR_CONNECTION_INITIATION_SECRET: {path: ['auth', 'connection_initiation_secret']},
	STAR_PROFILE_PSEUDONYM_SECRET: {path: ['auth', 'profile_pseudonym_secret']},
	STAR_SSO_ALLOW_PRIVATE_ADDRESSES: {path: ['auth', 'sso_allow_private_addresses'], parse: parseBoolean},
	STAR_VAPID_PUBLIC_KEY: {path: ['auth', 'vapid', 'public_key']},
	STAR_VAPID_PRIVATE_KEY: {path: ['auth', 'vapid', 'private_key']},
	STAR_VAPID_EMAIL: {path: ['auth', 'vapid', 'email']},
	STAR_PASSKEY_RP_NAME: {path: ['auth', 'passkeys', 'rp_name']},
	STAR_PASSKEY_RP_ID: {path: ['auth', 'passkeys', 'rp_id']},
	STAR_PASSKEY_ADDITIONAL_ALLOWED_ORIGINS: {
		path: ['auth', 'passkeys', 'additional_allowed_origins'],
		parse: parsePasskeyOrigins,
	},
	STAR_AUTH_BLUESKY_ENABLED: {path: ['auth', 'bluesky', 'enabled'], parse: parseBoolean},
	STAR_AUTH_BLUESKY_CLIENT_NAME: {path: ['auth', 'bluesky', 'client_name']},
	STAR_AUTH_BLUESKY_CLIENT_URI: {path: ['auth', 'bluesky', 'client_uri']},
	STAR_AUTH_BLUESKY_LOGO_URI: {path: ['auth', 'bluesky', 'logo_uri']},
	STAR_AUTH_BLUESKY_TOS_URI: {path: ['auth', 'bluesky', 'tos_uri']},
	STAR_AUTH_BLUESKY_POLICY_URI: {path: ['auth', 'bluesky', 'policy_uri']},
	STAR_AUTH_BLUESKY_KEYS: {path: ['auth', 'bluesky', 'keys'], parse: parseJsonArray},
	STAR_EMAIL_ENABLED: {path: ['integrations', 'email', 'enabled'], parse: parseBoolean},
	STAR_EMAIL_PROVIDER: {path: ['integrations', 'email', 'provider']},
	STAR_EMAIL_DELIVERY: {path: ['integrations', 'email', 'delivery']},
	STAR_EMAIL_FROM_EMAIL: {path: ['integrations', 'email', 'from_email']},
	STAR_EMAIL_FROM_NAME: {path: ['integrations', 'email', 'from_name']},
	STAR_EMAIL_REPLY_TO_EMAIL: {path: ['integrations', 'email', 'reply_to_email']},
	STAR_EMAIL_SUPPORT_ALERT_EMAIL: {path: ['integrations', 'email', 'support_alert_email']},
	STAR_EMAIL_APP_BASE_URL: {path: ['integrations', 'email', 'app_base_url']},
	STAR_EMAIL_WEBHOOK_SECRET: {path: ['integrations', 'email', 'webhook_secret']},
	STAR_EMAIL_SMTP_HOST: {path: ['integrations', 'email', 'smtp', 'host']},
	STAR_EMAIL_SMTP_PORT: {path: ['integrations', 'email', 'smtp', 'port'], parse: parseInteger},
	STAR_EMAIL_SMTP_USERNAME: {path: ['integrations', 'email', 'smtp', 'username']},
	STAR_EMAIL_SMTP_PASSWORD: {path: ['integrations', 'email', 'smtp', 'password']},
	STAR_EMAIL_SMTP_TLS_MODE: {path: ['integrations', 'email', 'smtp', 'tls_mode'], parse: parseSmtpTlsMode},
	STAR_EMAIL_SMTP_SECURE: {path: ['integrations', 'email', 'smtp', 'secure'], parse: parseBoolean},
	STAR_EMAIL_FALLBACK_DOMAINS: {path: ['integrations', 'email', 'fallback', 'domains'], parse: parseCsv},
	STAR_EMAIL_FALLBACK_SMTP_HOST: {path: ['integrations', 'email', 'fallback', 'smtp', 'host']},
	STAR_EMAIL_FALLBACK_SMTP_PORT: {path: ['integrations', 'email', 'fallback', 'smtp', 'port'], parse: parseInteger},
	STAR_EMAIL_FALLBACK_SMTP_USERNAME: {path: ['integrations', 'email', 'fallback', 'smtp', 'username']},
	STAR_EMAIL_FALLBACK_SMTP_PASSWORD: {path: ['integrations', 'email', 'fallback', 'smtp', 'password']},
	STAR_EMAIL_FALLBACK_SMTP_TLS_MODE: {
		path: ['integrations', 'email', 'fallback', 'smtp', 'tls_mode'],
		parse: parseSmtpTlsMode,
	},
	STAR_EMAIL_FALLBACK_SMTP_HEADERS: {
		path: ['integrations', 'email', 'fallback', 'smtp', 'headers'],
		parse: parseJsonObject,
	},
	STAR_LIVEKIT_ENABLED: {path: ['integrations', 'voice', 'enabled'], parse: parseBoolean},
	STAR_LIVEKIT_API_KEY: {path: ['integrations', 'voice', 'api_key']},
	STAR_LIVEKIT_API_SECRET: {path: ['integrations', 'voice', 'api_secret']},
	STAR_LIVEKIT_URL: {path: ['integrations', 'voice', 'url']},
	STAR_LIVEKIT_INTERNAL_URL: {path: ['integrations', 'voice', 'internal_url']},
	STAR_LIVEKIT_BUNDLED: {path: ['integrations', 'voice', 'bundled'], parse: parseBoolean},
	STAR_LIVEKIT_DEFAULT_REGION: {path: ['integrations', 'voice', 'default_region'], parse: parseJsonObject},
	STAR_VOICE_P2P_STUN_URLS: {path: ['integrations', 'voice', 'p2p_stun_urls'], parse: parseCsv},
	STAR_LIVEKIT_TURN_SERVERS: {path: ['integrations', 'voice', 'turn_servers'], parse: parseTurnServers},
	STAR_VOICE_JOIN_ALLOW_PRIVATE_ENDPOINTS: {
		path: ['integrations', 'voice', 'join_allow_private_endpoints'],
		parse: parseBoolean,
	},
	STAR_VOICE_HEALTH_INTERVAL_MS: {path: ['integrations', 'voice', 'health_interval_ms'], parse: parseInteger},
	STAR_VOICE_PARTICIPANT_SWEEP_ENABLED: {
		path: ['integrations', 'voice', 'participant_sweep_enabled'],
		parse: parseBoolean,
	},
	STAR_VOICE_PARTICIPANT_SWEEP_DRY_RUN: {
		path: ['integrations', 'voice', 'participant_sweep_dry_run'],
		parse: parseBoolean,
	},
	STAR_SEARCH_ENGINE: {path: ['integrations', 'search', 'engine']},
	STAR_SEARCH_URL: {path: ['integrations', 'search', 'url']},
	STAR_SEARCH_API_KEY: {path: ['integrations', 'search', 'api_key']},
	STAR_SEARCH_USERNAME: {path: ['integrations', 'search', 'username']},
	STAR_SEARCH_PASSWORD: {path: ['integrations', 'search', 'password']},
	STAR_SEARCH_TLS_REJECT_UNAUTHORIZED: {
		path: ['integrations', 'search', 'tls_reject_unauthorized'],
		parse: parseBoolean,
	},
	STAR_STRIPE_ENABLED: {path: ['integrations', 'stripe', 'enabled'], parse: parseBoolean},
	STAR_STRIPE_SECRET_KEY: {path: ['integrations', 'stripe', 'secret_key']},
	STAR_STRIPE_WEBHOOK_SECRET: {path: ['integrations', 'stripe', 'webhook_secret']},
	STAR_STRIPE_PRICES: {path: ['integrations', 'stripe', 'prices'], parse: parseJsonObject},
	STAR_STRIPE_LEGACY_PRICES: {path: ['integrations', 'stripe', 'legacy_prices'], parse: parseJsonObject},
	STAR_STRIPE_PRICE_MONTHLY_USD: {path: ['integrations', 'stripe', 'prices', 'monthly_usd']},
	STAR_STRIPE_PRICE_MONTHLY_EUR: {path: ['integrations', 'stripe', 'prices', 'monthly_eur']},
	STAR_STRIPE_PRICE_MONTHLY_BRL: {path: ['integrations', 'stripe', 'prices', 'monthly_brl']},
	STAR_STRIPE_PRICE_MONTHLY_DKK: {path: ['integrations', 'stripe', 'prices', 'monthly_dkk']},
	STAR_STRIPE_PRICE_MONTHLY_INR: {path: ['integrations', 'stripe', 'prices', 'monthly_inr']},
	STAR_STRIPE_PRICE_MONTHLY_ISK: {path: ['integrations', 'stripe', 'prices', 'monthly_isk']},
	STAR_STRIPE_PRICE_MONTHLY_NOK: {path: ['integrations', 'stripe', 'prices', 'monthly_nok']},
	STAR_STRIPE_PRICE_MONTHLY_PLN: {path: ['integrations', 'stripe', 'prices', 'monthly_pln']},
	STAR_STRIPE_PRICE_MONTHLY_SEK: {path: ['integrations', 'stripe', 'prices', 'monthly_sek']},
	STAR_STRIPE_PRICE_MONTHLY_TRY: {path: ['integrations', 'stripe', 'prices', 'monthly_try']},
	STAR_STRIPE_PRICE_YEARLY_USD: {path: ['integrations', 'stripe', 'prices', 'yearly_usd']},
	STAR_STRIPE_PRICE_YEARLY_EUR: {path: ['integrations', 'stripe', 'prices', 'yearly_eur']},
	STAR_STRIPE_PRICE_YEARLY_BRL: {path: ['integrations', 'stripe', 'prices', 'yearly_brl']},
	STAR_STRIPE_PRICE_YEARLY_DKK: {path: ['integrations', 'stripe', 'prices', 'yearly_dkk']},
	STAR_STRIPE_PRICE_YEARLY_INR: {path: ['integrations', 'stripe', 'prices', 'yearly_inr']},
	STAR_STRIPE_PRICE_YEARLY_ISK: {path: ['integrations', 'stripe', 'prices', 'yearly_isk']},
	STAR_STRIPE_PRICE_YEARLY_NOK: {path: ['integrations', 'stripe', 'prices', 'yearly_nok']},
	STAR_STRIPE_PRICE_YEARLY_PLN: {path: ['integrations', 'stripe', 'prices', 'yearly_pln']},
	STAR_STRIPE_PRICE_YEARLY_SEK: {path: ['integrations', 'stripe', 'prices', 'yearly_sek']},
	STAR_STRIPE_PRICE_YEARLY_TRY: {path: ['integrations', 'stripe', 'prices', 'yearly_try']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_USD: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_usd']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_EUR: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_eur']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_SEK: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_sek']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_SEK: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_sek']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_DKK: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_dkk']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_DKK: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_dkk']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_NOK: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_nok']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_NOK: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_nok']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_ISK: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_isk']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_ISK: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_isk']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_BRL: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_brl']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_INR: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_inr']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_PLN: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_pln']},
	STAR_STRIPE_PRICE_GIFT_1_MONTH_TRY: {path: ['integrations', 'stripe', 'prices', 'gift_1_month_try']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_USD: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_usd']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_EUR: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_eur']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_BRL: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_brl']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_INR: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_inr']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_PLN: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_pln']},
	STAR_STRIPE_PRICE_GIFT_1_YEAR_TRY: {path: ['integrations', 'stripe', 'prices', 'gift_1_year_try']},
	STAR_CLAMAV_ENABLED: {path: ['integrations', 'clamav', 'enabled'], parse: parseBoolean},
	STAR_CLAMAV_HOST: {path: ['integrations', 'clamav', 'host']},
	STAR_CLAMAV_PORT: {path: ['integrations', 'clamav', 'port'], parse: parseInteger},
	STAR_CLAMAV_FAIL_OPEN: {path: ['integrations', 'clamav', 'fail_open'], parse: parseBoolean},
	STAR_KLIPY_API_KEY: {path: ['integrations', 'klipy', 'api_key']},
	STAR_YOUTUBE_API_KEY: {path: ['integrations', 'youtube', 'api_key']},
	STAR_CACHE_PURGE_ADAPTER: {path: ['integrations', 'cache_purge', 'adapter']},
	STAR_CACHE_PURGE_HTTP_ENDPOINT: {path: ['integrations', 'cache_purge', 'http', 'endpoint']},
	STAR_CACHE_PURGE_HTTP_TOKEN: {path: ['integrations', 'cache_purge', 'http', 'token']},
	STAR_CACHE_PURGE_HTTP_TIMEOUT_MS: {
		path: ['integrations', 'cache_purge', 'http', 'timeout_ms'],
		parse: parseInteger,
	},
	STAR_CACHE_PURGE_CONTROLLER_ENDPOINT: {path: ['integrations', 'cache_purge', 'controller', 'endpoint']},
	STAR_CACHE_PURGE_CONTROLLER_TOKEN: {path: ['integrations', 'cache_purge', 'controller', 'token']},
	STAR_CACHE_PURGE_CONTROLLER_TIMEOUT_MS: {
		path: ['integrations', 'cache_purge', 'controller', 'timeout_ms'],
		parse: parseInteger,
	},
	STAR_BLOCKLIST_FEEDS_ENABLED: {path: ['integrations', 'blocklist_feeds', 'enabled'], parse: parseBoolean},
	STAR_BREACHED_PASSWORD_CHECK_ENABLED: {
		path: ['integrations', 'breached_password_check', 'enabled'],
		parse: parseBoolean,
	},
	STAR_APP_STORE_ENABLED: {path: ['integrations', 'app_store', 'enabled'], parse: parseBoolean},
	STAR_APP_STORE_ISSUER_ID: {path: ['integrations', 'app_store', 'issuer_id']},
	STAR_APP_STORE_KEY_ID: {path: ['integrations', 'app_store', 'key_id']},
	STAR_APP_STORE_PRIVATE_KEY: {path: ['integrations', 'app_store', 'private_key']},
	STAR_APP_STORE_PRIVATE_KEY_PATH: {path: ['integrations', 'app_store', 'private_key_path']},
	STAR_APP_STORE_APPS: {path: ['integrations', 'app_store', 'apps'], parse: parseJsonArray},
	STAR_APP_STORE_PRODUCTS: {path: ['integrations', 'app_store', 'products'], parse: parseJsonObject},
	STAR_GOOGLE_PLAY_ENABLED: {path: ['integrations', 'google_play', 'enabled'], parse: parseBoolean},
	STAR_GOOGLE_PLAY_PACKAGES: {path: ['integrations', 'google_play', 'packages'], parse: parseCsv},
	STAR_GOOGLE_PLAY_CLIENT_EMAIL: {path: ['integrations', 'google_play', 'client_email']},
	STAR_GOOGLE_PLAY_PRIVATE_KEY: {path: ['integrations', 'google_play', 'private_key']},
	STAR_GOOGLE_PLAY_PRIVATE_KEY_PATH: {path: ['integrations', 'google_play', 'private_key_path']},
	STAR_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_PATH: {path: ['integrations', 'google_play', 'service_account_json_path']},
	STAR_GOOGLE_PLAY_TOKEN_URI: {path: ['integrations', 'google_play', 'token_uri']},
	STAR_GOOGLE_PLAY_PRODUCTS: {path: ['integrations', 'google_play', 'products'], parse: parseJsonObject},
	STAR_GOOGLE_PLAY_PUSH_AUDIENCE: {path: ['integrations', 'google_play', 'push_audience']},
	STAR_GOOGLE_PLAY_PUSH_SERVICE_ACCOUNT_EMAIL: {
		path: ['integrations', 'google_play', 'push_service_account_email'],
	},
	STAR_GOOGLE_PLAY_SELF_SERVICE_REFUNDS: {
		path: ['integrations', 'google_play', 'self_service_refunds'],
		parse: parseBoolean,
	},
	STAR_STORE_BILLING_SANDBOX_USER_IDS: {path: ['integrations', 'store_billing', 'sandbox_user_ids'], parse: parseCsv},
	STAR_STORE_BILLING_SANDBOX_ENTITLES_ALL: {
		path: ['integrations', 'store_billing', 'sandbox_entitles_all'],
		parse: parseBoolean,
	},
	STAR_STORE_BILLING_SANDBOX_SUBSCRIPTIONS: {
		path: ['integrations', 'store_billing', 'sandbox_subscriptions'],
		parse: parseBoolean,
	},
	STAR_SELF_HOSTED: {path: ['instance', 'self_hosted'], parse: parseBoolean},
	STAR_AUTO_JOIN_INVITE_CODE: {path: ['instance', 'auto_join_invite_code']},
	STAR_VISIONARIES_GUILD_ID: {path: ['instance', 'visionaries_guild_id']},
	STAR_VISIONARIES_GUILD_VISIONARY_ROLE_ID: {path: ['instance', 'visionaries_guild_visionary_role_id']},
	STAR_LABS_GUILD_ID: {path: ['operator_pass', 'labs_guild_id']},
	STAR_LABS_OPERATOR_ROLE_ID: {path: ['operator_pass', 'labs_operator_role_id']},
	STAR_LABS_VISIONARY_ROLE_ID: {path: ['operator_pass', 'labs_visionary_role_id']},
	STAR_LABS_OPERATORS_CHANNEL_ID: {path: ['operator_pass', 'labs_operators_channel_id']},
	STAR_PAYMENT_DISPUTE_CLOSURE_EFFECTIVE_AT: {path: ['payment_disputes', 'closure_effective_at']},
	STAR_OPERATOR_PASS_PRICE_RISES_AT: {path: ['operator_pass', 'price_rises_at']},
	STAR_OPERATOR_PASS_GRACE_MINUTES: {path: ['operator_pass', 'grace_minutes'], parse: parseInteger},
	STAR_OPERATOR_PASS_NOW: {path: ['operator_pass', 'now_override']},
	STAR_OPERATOR_PASS_STANDARD_PRICE_USD: {
		path: ['operator_pass', 'standard_prices_minor', 'usd'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_STANDARD_PRICE_EUR: {
		path: ['operator_pass', 'standard_prices_minor', 'eur'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_STANDARD_PRICE_BRL: {
		path: ['operator_pass', 'standard_prices_minor', 'brl'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_STANDARD_PRICE_DKK: {
		path: ['operator_pass', 'standard_prices_minor', 'dkk'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_STANDARD_PRICE_INR: {
		path: ['operator_pass', 'standard_prices_minor', 'inr'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_STANDARD_PRICE_NOK: {
		path: ['operator_pass', 'standard_prices_minor', 'nok'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_STANDARD_PRICE_PLN: {
		path: ['operator_pass', 'standard_prices_minor', 'pln'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_STANDARD_PRICE_SEK: {
		path: ['operator_pass', 'standard_prices_minor', 'sek'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_STANDARD_PRICE_TRY: {
		path: ['operator_pass', 'standard_prices_minor', 'try'],
		parse: parseInteger,
	},
	STAR_OPERATOR_PASS_RELEASE_LISTS: {path: ['operator_pass', 'release_lists']},
	STAR_OPERATOR_PASS_WITHDRAWAL_COUNTRIES: {path: ['operator_pass', 'withdrawal_countries']},
	STAR_OPERATOR_PASS_WALL_TIERS: {path: ['operator_pass', 'wall_tiers']},
	STAR_OPERATOR_PASS_MAX_QUANTITY: {path: ['operator_pass', 'max_quantity'], parse: parseInteger},
	STAR_OPERATOR_PASS_PRICE_BRL_ENABLED: {
		path: ['operator_pass', 'localized_prices_enabled', 'brl'],
		parse: parseBoolean,
	},
	STAR_OPERATOR_PASS_PRICE_DKK_ENABLED: {
		path: ['operator_pass', 'localized_prices_enabled', 'dkk'],
		parse: parseBoolean,
	},
	STAR_OPERATOR_PASS_PRICE_INR_ENABLED: {
		path: ['operator_pass', 'localized_prices_enabled', 'inr'],
		parse: parseBoolean,
	},
	STAR_OPERATOR_PASS_PRICE_NOK_ENABLED: {
		path: ['operator_pass', 'localized_prices_enabled', 'nok'],
		parse: parseBoolean,
	},
	STAR_OPERATOR_PASS_PRICE_PLN_ENABLED: {
		path: ['operator_pass', 'localized_prices_enabled', 'pln'],
		parse: parseBoolean,
	},
	STAR_OPERATOR_PASS_PRICE_SEK_ENABLED: {
		path: ['operator_pass', 'localized_prices_enabled', 'sek'],
		parse: parseBoolean,
	},
	STAR_OPERATOR_PASS_PRICE_TRY_ENABLED: {
		path: ['operator_pass', 'localized_prices_enabled', 'try'],
		parse: parseBoolean,
	},
	STAR_APP_PRODUCT_NAME: {path: ['instance', 'branding', 'product_name']},
	STAR_APP_ICON_URL: {path: ['instance', 'branding', 'icon_url']},
	STAR_APP_SYMBOL_URL: {path: ['instance', 'branding', 'symbol_url']},
	STAR_APP_LOGO_URL: {path: ['instance', 'branding', 'logo_url']},
	STAR_APP_WORDMARK_URL: {path: ['instance', 'branding', 'wordmark_url']},
	STAR_APP_FAVICON_URL: {path: ['instance', 'branding', 'favicon_url']},
	STAR_APP_FAVICON_DARK_URL: {path: ['instance', 'branding', 'favicon_dark_url']},
	STAR_APP_SIGN_IN_BACKDROP_URL: {path: ['instance', 'branding', 'sign_in_backdrop_url']},
	STAR_APP_THEME_COLOR: {path: ['instance', 'branding', 'theme_color']},
	STAR_APP_STATUS_PAGE_URL: {path: ['instance', 'branding', 'status_page_url']},
	STAR_APP_STATUS_PAGE_INCIDENT_HISTORY_URL: {path: ['instance', 'branding', 'status_page_incident_history_url']},
	STAR_INSTANCE_SETUP_CONFIGURED: {path: ['instance', 'setup', 'configured'], parse: parseBoolean},
	STAR_SETUP_TOKEN: {path: ['instance', 'setup', 'token']},
	STAR_ACCOUNT_IDENTITY: {path: ['instance', 'account_identity'], parse: parseAccountIdentity},
	STAR_TAG_STYLE: {path: ['instance', 'tag_style'], parse: parseTagStyle},
	STAR_AGE_POLICY_ENABLED: {path: ['instance', 'age_policy', 'enabled'], parse: parseBoolean},
	STAR_AGE_POLICY_RESTRICTED_REGIONS: {path: ['instance', 'age_policy', 'restricted_regions'], parse: parseCsv},
	STAR_DISCOVERY_ENABLED: {path: ['discovery', 'enabled'], parse: parseBoolean},
	STAR_DISCOVERY_MIN_MEMBER_COUNT: {path: ['discovery', 'min_member_count'], parse: parseInteger},
	STAR_DELETION_GRACE_PERIOD_HOURS: {path: ['deletion_grace_period_hours'], parse: parseInteger},
	STAR_REPORT_RETENTION_DAYS: {path: ['report_retention', 'days'], parse: parseInteger},
	STAR_REPORT_RETENTION_DRY_RUN: {path: ['report_retention', 'dry_run'], parse: parseBoolean},
	STAR_RELAX_REGISTRATION_RATE_LIMITS: {path: ['dev', 'relax_registration_rate_limits'], parse: parseBoolean},
	STAR_DISABLE_RATE_LIMITS: {path: ['dev', 'disable_rate_limits'], parse: parseBoolean},
	STAR_TEST_MODE_ENABLED: {path: ['dev', 'test_mode_enabled'], parse: parseBoolean},
	STAR_TEST_HARNESS_TOKEN: {path: ['dev', 'test_harness_token']},
	STAR_VALIDATE_RESPONSES: {path: ['dev', 'validate_responses'], parse: parseBoolean},
	STAR_GEOIP_DB_PATH: {path: ['geoip', 'maxmind_db_path']},
};

function isContainer(value: unknown): value is ConfigContainer {
	return isConfigObject(value) || Array.isArray(value);
}

function createChildContainer(nextKey: ConfigPathKey | undefined): ConfigContainer {
	return typeof nextKey === 'number' ? [] : {};
}

function getChildValue(target: ConfigContainer, key: ConfigPathKey): unknown {
	return Object.hasOwn(target, key) ? Reflect.get(target, key) : undefined;
}

function setChildValue(target: ConfigContainer, key: ConfigPathKey, value: unknown): void {
	if (key === '__proto__') {
		Object.defineProperty(target, key, {value, writable: true, enumerable: true, configurable: true});
		return;
	}
	if (Array.isArray(target) && typeof key === 'number') {
		target[key] = value;
		return;
	}
	(target as ConfigObject)[String(key)] = value;
}

function parseBoolean(raw: string): boolean {
	switch (raw.trim().toLowerCase()) {
		case 'true':
			return true;
		case 'false':
			return false;
		default:
			throw new Error('must be true or false');
	}
}

function parseAccountIdentity(raw: string): string {
	const value = raw.trim().toLowerCase();
	if (value === 'email' || value === 'username') return value;
	throw new Error('must be email or username');
}

function parseTagStyle(raw: string): string {
	const value = raw.trim().toLowerCase();
	if (value === 'none' || value === 'random') return value;
	throw new Error('must be none or random');
}

function parseSmtpTlsMode(raw: string): string {
	const value = raw.trim().toLowerCase();
	if (value === 'implicit' || value === 'starttls' || value === 'opportunistic' || value === 'none') return value;
	throw new Error('must be implicit, starttls, opportunistic or none');
}

function parseJson(raw: string): unknown {
	try {
		return JSON.parse(raw);
	} catch {
		throw new Error('must be valid JSON');
	}
}

function parseJsonObject(raw: string): ConfigObject {
	const value = parseJson(raw);
	if (isConfigObject(value)) return value;
	throw new Error('must be a JSON object');
}

function parseJsonArray(raw: string): Array<unknown> {
	const value = parseJson(raw);
	if (Array.isArray(value)) return value;
	throw new Error('must be a JSON array');
}

const TURN_SERVER_FIELDS = new Set(['host', 'port', 'protocol', 'username', 'credential', 'secret', 'ttl']);

function optionalString(entry: ConfigObject, key: string, n: number): string | undefined {
	const value = entry[key];
	if (value === undefined) return undefined;
	if (typeof value !== 'string' || value === '') throw new Error(`entry ${n} must have a text ${key}`);
	return value;
}

function parseTurnServers(raw: string): Array<ConfigObject> {
	if (raw.trim() === '') return [];
	return parseJsonArray(raw).map((entry, index) => {
		const n = index + 1;
		if (!isConfigObject(entry)) throw new Error(`entry ${n} must be a JSON object`);
		for (const key of Object.keys(entry)) {
			if (!TURN_SERVER_FIELDS.has(key)) throw new Error(`entry ${n} has the unknown field ${key}`);
		}
		const {host, port, protocol, ttl} = entry;
		if (typeof host !== 'string' || host === '' || /[:/\s[\]]/.test(host)) {
			throw new Error(`entry ${n} must have a host that is a hostname or an IPv4 address`);
		}
		if (typeof port !== 'number' || !Number.isInteger(port) || port < 1 || port > 65535) {
			throw new Error(`entry ${n} must have a port from 1 to 65535`);
		}
		if (protocol !== 'udp' && protocol !== 'tcp' && protocol !== 'tls') {
			throw new Error(`entry ${n} must have the protocol udp, tcp or tls`);
		}
		const username = optionalString(entry, 'username', n);
		const credential = optionalString(entry, 'credential', n);
		const secret = optionalString(entry, 'secret', n);
		if (secret !== undefined && (username !== undefined || credential !== undefined)) {
			throw new Error(`entry ${n} must have a secret, or a username and credential, and not both`);
		}
		if ((username === undefined) !== (credential === undefined)) {
			throw new Error(`entry ${n} must have both a username and a credential`);
		}
		if (ttl !== undefined && (secret === undefined || typeof ttl !== 'number' || !Number.isInteger(ttl) || ttl < 1)) {
			throw new Error(`entry ${n} may have a ttl only with a secret, as a whole number of seconds`);
		}
		return entry;
	});
}

function parseInteger(raw: string): number {
	const trimmed = raw.trim();
	if (!/^-?\d+$/.test(trimmed)) {
		throw new Error(`must be an integer, got ${JSON.stringify(raw)}`);
	}
	const value = Number(trimmed);
	if (!Number.isSafeInteger(value)) throw new Error('must be a safe integer');
	return value;
}

function parseCsv(raw: string): Array<string> {
	return raw
		.split(',')
		.map((part) => part.trim())
		.filter((part) => part.length > 0);
}

function parseBucketList(raw: string): Array<string> {
	return raw.trim().toLowerCase() === 'none' ? [] : parseCsv(raw);
}

function parsePasskeyOrigins(raw: string): Array<string> {
	if (/\p{Cc}/u.test(raw)) {
		throw new Error('must not contain control characters');
	}
	return parseCsv(raw);
}

function setNestedValue(target: ConfigContainer, keys: Array<ConfigPathKey>, value: unknown): void {
	if (keys.length === 0) {
		return;
	}
	const [first, ...rest] = keys;
	if (rest.length === 0) {
		setChildValue(target, first, value);
		return;
	}
	const current = getChildValue(target, first);
	let child: ConfigContainer;
	if (isContainer(current)) {
		child = current;
	} else {
		child = createChildContainer(rest[0]);
		setChildValue(target, first, child);
	}
	setNestedValue(child, rest, value);
}

const NAMED_STAR_ENV_ALIASES: Record<string, string | undefined> = {
	STAR_INTERNAL_MEDIA_PROXY_ENDPOINT: 'STAR_MEDIA_PROXY_ENDPOINT',
	STAR_NATS_URL: 'STAR_NATS_CORE_URL',
	STAR_STORAGE_UPLOADS_TTL: 'STAR_SEAWEEDFS_UPLOADS_TTL',
};

function nonBlank(value: string | undefined): string | undefined {
	return value === undefined || value.trim().length === 0 ? undefined : value;
}

export function readEnvValue(env: NodeJS.ProcessEnv, name: string): string | undefined {
	const value = nonBlank(env[name]);
	const filePath = nonBlank(env[`${name}_FILE`]);
	if (filePath === undefined) {
		return value;
	}
	if (value !== undefined) {
		throw new Error(`${name} and ${name}_FILE are both set, set only one`);
	}
	let contents: string;
	try {
		contents = new TextDecoder('utf-8', {fatal: true}).decode(readFileSync(filePath));
	} catch (error) {
		const reason = error instanceof Error && 'code' in error ? String(error.code) : 'unreadable';
		throw new Error(`${name}_FILE could not read ${filePath} (${reason})`);
	}
	return nonBlank(contents.replace(/\r?\n$/, ''));
}

export function buildNamedStarEnvOverrides(env: NodeJS.ProcessEnv): ConfigObject {
	const overrides: ConfigObject = {};
	for (const [envKey, mapping] of Object.entries(NAMED_STAR_ENV_OVERRIDES)) {
		const alias = NAMED_STAR_ENV_ALIASES[envKey];
		const raw = readEnvValue(env, envKey) ?? (alias === undefined ? undefined : readEnvValue(env, alias));
		if (raw === undefined) {
			continue;
		}
		let parsed: unknown;
		try {
			parsed = mapping.parse ? mapping.parse(raw) : raw;
		} catch (error) {
			throw new Error(`${envKey} ${error instanceof Error ? error.message : String(error)}`);
		}
		setNestedValue(overrides, mapping.path, parsed);
	}
	return overrides;
}
