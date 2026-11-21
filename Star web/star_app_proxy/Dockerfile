# SPDX-License-Identifier: AGPL-3.0-or-later

ARG BUILD_VERSION=""
ARG PUBLIC_ASSET_BASE_URL=""
ARG BUNDLE_LOCAL_ASSETS="true"
ARG APP_ASSETS_REF=app-assets
ARG APP_ASSETS_PLATFORM=$BUILDPLATFORM

# ---------- Stage 1: Build the SPA (star_app) ----------
FROM node:26-trixie-slim AS app-build

ARG BUILD_VERSION
ARG PUBLIC_ASSET_BASE_URL

WORKDIR /usr/src/app

RUN npm install -g pnpm@11.27.0

RUN apt-get update && apt-get install -y --no-install-recommends \
	curl ca-certificates build-essential clang \
	&& rm -rf /var/lib/apt/lists/*

ARG RUST_VERSION=1.98.1
ENV RUSTUP_HOME=/usr/local/rustup \
	CARGO_HOME=/usr/local/cargo \
	PATH=/usr/local/cargo/bin:$PATH
RUN set -eux; \
	curl --retry 3 --retry-all-errors --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs \
		| sh -s -- -y --no-modify-path --profile minimal --default-toolchain "${RUST_VERSION}" \
			--target wasm32-unknown-unknown; \
	rustc --version; cargo --version


COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY patches/ ./patches/
COPY star_app/package.json ./star_app/
COPY packages/constants/package.json ./packages/constants/
COPY packages/date_utils/package.json ./packages/date_utils/
COPY packages/desktop_ipc/package.json ./packages/desktop_ipc/
COPY packages/geo_utils/package.json ./packages/geo_utils/
COPY packages/instance_bootstrap/package.json ./packages/instance_bootstrap/
COPY packages/limits/package.json ./packages/limits/
COPY packages/number_utils/package.json ./packages/number_utils/
COPY packages/record_utils/package.json ./packages/record_utils/
COPY packages/schema/package.json ./packages/schema/
COPY packages/snowflake/package.json ./packages/snowflake/
COPY packages/voice_engine_v2/package.json ./packages/voice_engine_v2/
COPY star_app/pkgs/livekit-client/package.json ./star_app/pkgs/livekit-client/

RUN pnpm install --frozen-lockfile --filter star_app...

COPY tsconfigs ./tsconfigs
COPY packages/constants/ ./packages/constants/
COPY packages/date_utils/ ./packages/date_utils/
COPY packages/desktop_ipc/ ./packages/desktop_ipc/
COPY packages/geo_utils/ ./packages/geo_utils/
COPY packages/instance_bootstrap/ ./packages/instance_bootstrap/
COPY packages/limits/ ./packages/limits/
COPY packages/number_utils/ ./packages/number_utils/
COPY packages/record_utils/ ./packages/record_utils/
COPY packages/schema/ ./packages/schema/
COPY packages/snowflake/ ./packages/snowflake/
COPY packages/voice_engine_v2/ ./packages/voice_engine_v2/
COPY packages/fonts/css/ ./packages/fonts/css/
COPY packages/fonts/files/ ./packages/fonts/files/
COPY packages/fonts/NOTICE.md packages/fonts/LICENSE-IBM-PLEX.txt packages/fonts/LICENSE-NOTO-SANS-BENGALI.txt ./packages/fonts/
COPY packages/markdown_parser/rust/Cargo.toml ./packages/markdown_parser/rust/
COPY packages/markdown_parser/rust/.cargo/ ./packages/markdown_parser/rust/.cargo/
COPY packages/markdown_parser/rust/benches/parser.rs ./packages/markdown_parser/rust/benches/
COPY packages/markdown_parser/rust/src/ ./packages/markdown_parser/rust/src/
COPY tools/ci/ ./tools/ci/
COPY star_app/index.html star_app/lingui.config.js star_app/package.json star_app/postcss.config.js star_app/rspack.config.mjs star_app/tsconfig.base.json star_app/tsconfig.json ./star_app/
COPY star_app/inline_scripts/ ./star_app/inline_scripts/
COPY star_app/pkgs/livekit-client/ ./star_app/pkgs/livekit-client/
COPY star_app/rust/ ./star_app/rust/
COPY Cargo.lock ./
RUN printf '%s\n' \
	'[workspace]' \
	'members = [' \
	'    "star_app/rust/libfluxcore",' \
	'    "star_app/rust/libfluxwebp",' \
	'    "packages/markdown_parser/rust",' \
	']' \
	'exclude = [' \
	'    "tools/ci",' \
	']' \
	'resolver = "2"' \
	'' \
	'[profile.wasm-release]' \
	'inherits = "release"' \
	'codegen-units = 1' \
	'lto = true' \
	'opt-level = "z"' \
	'panic = "abort"' \
	'strip = true' \
	> Cargo.toml \
	&& cargo update --workspace
COPY star_app/scripts/ ./star_app/scripts/
COPY star_app/src/ ./star_app/src/

ENV BUILD_VERSION=${BUILD_VERSION} \
	PUBLIC_ASSET_BASE_URL=${PUBLIC_ASSET_BASE_URL}

RUN --mount=type=cache,target=/usr/local/cargo/registry \
	--mount=type=cache,target=/usr/local/cargo/git \
	cd star_app && pnpm build

# ---------- Stage 2: The one canonical asset tree every architecture serves ----------
# Stage for CI to extract the full dist (docker bake app-dist target)
FROM alpine:3.24 AS app-dist
COPY --from=app-build /usr/src/app/star_app/dist /dist

FROM alpine:3.24 AS app-assets
ARG BUNDLE_LOCAL_ASSETS=true
ARG PUBLIC_ASSET_BASE_URL=""
COPY star_app_proxy/scripts/precompress_assets.sh /usr/local/bin/precompress_assets.sh
RUN apk add --no-cache brotli
RUN --mount=type=bind,from=app-dist,source=/dist,target=/dist \
	cp -a /dist /assets \
	&& if [ "${BUNDLE_LOCAL_ASSETS}" != "true" ]; then \
		case "${PUBLIC_ASSET_BASE_URL}" in \
		http://* | https://*) ;; \
		*) \
			echo "BUNDLE_LOCAL_ASSETS=false requires an absolute PUBLIC_ASSET_BASE_URL." >&2; \
			echo "Without one, index.html links same-origin /assets/* that this image would no longer contain." >&2; \
			exit 1 \
			;; \
		esac; \
		find /assets/assets -type f ! -name 'fonts-*.txt' -delete; \
	fi \
	&& find /assets/assets -type f -name '*.map' -delete \
	&& /usr/local/bin/precompress_assets.sh /assets

# Compiled desktop renderer, reused by native macOS and Windows installer jobs.
# This target extends the same source+dependencies as the web asset build,
# but builds the desktop-specific renderer with no Electron native modules.
FROM app-build AS desktop-app-build
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    cd star_app && pnpm build:desktop

FROM alpine:3.24 AS desktop-renderer
COPY --from=desktop-app-build /usr/src/app/star_app/dist/ /renderer/
RUN test -s /renderer/index.html \
    && test -d /renderer/assets \
    && test -s /renderer/version.json

FROM --platform=${APP_ASSETS_PLATFORM} ${APP_ASSETS_REF} AS app-static

# ---------- Stage 3: Build the Rust proxy binary ----------
FROM rust:1.98.1-trixie@sha256:a8a5f0a1e5fe7dfe1d352591e4a1c7dd2c08fd70475cae872cf3458ba0df0546 AS rust-builder


WORKDIR /usr/src/app

COPY Cargo.lock ./
COPY star_common/ star_common/
COPY star_app_proxy/ star_app_proxy/

RUN printf '%s\n' \
	'[workspace]' \
	'members = [' \
	'    "star_app_proxy",' \
	'    "star_common",' \
	']' \
	'resolver = "2"' \
	'' \
	'[workspace.package]' \
	'edition = "2024"' \
	'license = "AGPL-3.0-or-later"' \
	'' \
	'[profile.release]' \
	'lto = "fat"' \
	'codegen-units = 1' \
	'strip = "symbols"' \
	> Cargo.toml

RUN cargo build --release -p star_app_proxy \
	&& cp target/release/star_app_proxy /usr/local/bin/star-app-proxy

# ---------- Stage 4: Runtime ----------
FROM debian:trixie-slim

ARG BUILD_VERSION=""
ARG PUBLIC_ASSET_BASE_URL=""
ARG STAR_SELF_HOSTED="false"
ARG SOURCE_SHA=""
ARG SOURCE_DATE=""

LABEL org.opencontainers.image.title="star-app-proxy"
LABEL org.opencontainers.image.description="Star web app and edge proxy"
LABEL org.opencontainers.image.licenses="AGPL-3.0-or-later"
LABEL org.opencontainers.image.vendor="Star"
LABEL org.opencontainers.image.url="https://star.invalid"
LABEL org.opencontainers.image.documentation="https://docs.star.invalid"
LABEL org.opencontainers.image.source="https://github.com/starapp/star"
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
LABEL org.opencontainers.image.revision="${SOURCE_SHA}"
LABEL org.opencontainers.image.created="${SOURCE_DATE}"
LABEL app.star.build-version="${BUILD_VERSION}"

WORKDIR /srv/app

RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates curl libjemalloc2 \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=rust-builder /usr/local/bin/star-app-proxy /usr/local/bin/star-app-proxy
COPY --from=app-static /assets ./static/

ENV BUILD_VERSION="${BUILD_VERSION}"
ENV STAR_SELF_HOSTED="${STAR_SELF_HOSTED}"
ENV STAR_STATIC_CDN_ENDPOINT="${PUBLIC_ASSET_BASE_URL}"
ENV STAR_APP_PROXY_HOST="0.0.0.0"
ENV STAR_APP_PROXY_PORT="8080"
ENV LD_PRELOAD=libjemalloc.so.2
ENV MALLOC_CONF="background_thread:true,metadata_thp:auto,dirty_decay_ms:5000,muzzy_decay_ms:5000"

USER 65532:65532

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
	CMD curl -f http://127.0.0.1:${STAR_APP_PROXY_PORT:-8080}/_ready || exit 1

CMD ["/usr/local/bin/star-app-proxy"]
