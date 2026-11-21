// SPDX-License-Identifier: AGPL-3.0-or-later

package settings

var Twins = map[string]string{
	"STAR_APP_FAVICON_DARK_URL":                 "app_public.branding.favicon_dark_url",
	"STAR_APP_FAVICON_URL":                      "app_public.branding.favicon_url",
	"STAR_APP_ICON_URL":                         "app_public.branding.icon_url",
	"STAR_APP_LOGO_URL":                         "app_public.branding.logo_url",
	"STAR_APP_PRODUCT_NAME":                     "app_public.branding.product_name",
	"STAR_APP_SIGN_IN_BACKDROP_URL":             "app_public.branding.sign_in_backdrop_url",
	"STAR_APP_STATUS_PAGE_INCIDENT_HISTORY_URL": "app_public.branding.status_page_incident_history_url",
	"STAR_APP_STATUS_PAGE_URL":                  "app_public.branding.status_page_url",
	"STAR_APP_SYMBOL_URL":                       "app_public.branding.symbol_url",
	"STAR_APP_THEME_COLOR":                      "app_public.branding.theme_color",
	"STAR_APP_WORDMARK_URL":                     "app_public.branding.wordmark_url",
	"STAR_AUTH_BLUESKY_CLIENT_NAME":             "integrations.bluesky.client_name",
	"STAR_AUTH_BLUESKY_CLIENT_URI":              "integrations.bluesky.client_uri",
	"STAR_AUTH_BLUESKY_ENABLED":                 "integrations.bluesky.enabled",
	"STAR_AUTH_BLUESKY_KEYS":                    "integrations.bluesky.keys",
	"STAR_AUTH_BLUESKY_LOGO_URI":                "integrations.bluesky.logo_uri",
	"STAR_AUTH_BLUESKY_POLICY_URI":              "integrations.bluesky.policy_uri",
	"STAR_AUTH_BLUESKY_TOS_URI":                 "integrations.bluesky.tos_uri",
	"STAR_EMAIL_DELIVERY":                       "integrations.email.delivery",
	"STAR_EMAIL_ENABLED":                        "integrations.email.delivery",
	"STAR_EMAIL_FROM_EMAIL":                     "integrations.email.from_email",
	"STAR_EMAIL_FROM_NAME":                      "integrations.email.from_name",
	"STAR_EMAIL_PROVIDER":                       "integrations.email.delivery",
	"STAR_EMAIL_SMTP_HOST":                      "integrations.email.smtp.host",
	"STAR_EMAIL_SMTP_PASSWORD":                  "integrations.email.smtp.password",
	"STAR_EMAIL_SMTP_PORT":                      "integrations.email.smtp.port",
	"STAR_EMAIL_SMTP_SECURE":                    "integrations.email.smtp.tls_mode",
	"STAR_EMAIL_SMTP_TLS_MODE":                  "integrations.email.smtp.tls_mode",
	"STAR_EMAIL_SMTP_USERNAME":                  "integrations.email.smtp.username",
	"STAR_KLIPY_API_KEY":                        "integrations.gif.klipy_api_key",
	"STAR_STRIPE_ENABLED":                       "billing.enabled",
	"STAR_STRIPE_LEGACY_PRICES":                 "billing.legacy_prices",
	"STAR_STRIPE_PRICES":                        "billing.prices",
	"STAR_STRIPE_SECRET_KEY":                    "billing.stripe_secret_key",
	"STAR_STRIPE_WEBHOOK_SECRET":                "billing.stripe_webhook_secret",
	"STAR_YOUTUBE_API_KEY":                      "integrations.youtube.api_key",
}

var twinVars = map[string]string{
	"integrations.email.delivery":      "STAR_EMAIL_DELIVERY",
	"integrations.email.smtp.tls_mode": "STAR_EMAIL_SMTP_TLS_MODE",
}

func TwinVar(adminKey string) (string, bool) {
	if v, ok := twinVars[adminKey]; ok {
		return v, true
	}
	for v, k := range Twins {
		if k == adminKey {
			return v, true
		}
	}
	return "", false
}
