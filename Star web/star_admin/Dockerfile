# SPDX-License-Identifier: AGPL-3.0-or-later

FROM rust:1.98.1-trixie@sha256:a8a5f0a1e5fe7dfe1d352591e4a1c7dd2c08fd70475cae872cf3458ba0df0546 AS builder

ARG TARGETARCH

WORKDIR /usr/src/app

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates nodejs npm pkg-config \
	&& npm install -g pnpm@11.27.0 \
	&& rm -rf /var/lib/apt/lists/*

RUN npm install --no-audit --no-fund @tailwindcss/cli@4.2.1 tailwindcss@4.2.1
RUN TAILWIND_OXIDE_VERSION="4.2.1" \
	&& case "${TARGETARCH}" in \
		amd64) OXIDE_PKG="@tailwindcss/oxide-linux-x64-gnu" ;; \
		arm64) OXIDE_PKG="@tailwindcss/oxide-linux-arm64-gnu" ;; \
		*) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
	esac \
	&& npm install --no-audit --no-fund "${OXIDE_PKG}@${TAILWIND_OXIDE_VERSION}" \
	&& ls -la node_modules/.bin/tailwindcss

COPY Cargo.lock Cargo.lock
COPY star_admin star_admin
COPY star_common star_common
COPY packages/fonts/manifest.json packages/fonts/manifest.json
COPY packages/fonts/NOTICE.md packages/fonts/NOTICE.md
COPY packages/fonts/LICENSE-IBM-PLEX.txt packages/fonts/LICENSE-IBM-PLEX.txt
COPY packages/fonts/files/StarSans packages/fonts/files/StarSans
COPY packages/fonts/files/StarMono packages/fonts/files/StarMono
RUN printf '%s\n' \
	'[workspace]' \
	'members = ["star_admin", "star_common"]' \
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

RUN cargo build --release -p star_admin \
	&& cp target/release/star_admin /usr/local/bin/star-admin

RUN static="$(find target/release/build -type d -path '*star_admin*/out/static')" \
	&& test "$(printf '%s\n' "$static" | wc -l)" -eq 1 \
	&& test -s "$static/app.css" \
	&& echo "Tailwind CSS compiled successfully" \
	&& test "$(ls "$static"/fonts/*.woff2 | wc -l)" -eq 16 \
	&& ls "$static"/fonts/fonts.*.css \
	&& echo "Latin-core fonts bundled successfully"

FROM debian:trixie-slim AS runtime

ARG BUILD_VERSION=""
ARG SOURCE_SHA=""
ARG SOURCE_DATE=""

LABEL org.opencontainers.image.title="star-admin"
LABEL org.opencontainers.image.description="Star admin console"
LABEL org.opencontainers.image.licenses="AGPL-3.0-or-later"
LABEL org.opencontainers.image.vendor="Star"
LABEL org.opencontainers.image.url="https://star.invalid"
LABEL org.opencontainers.image.documentation="https://docs.star.invalid"
LABEL org.opencontainers.image.source="https://github.com/starapp/star"
LABEL org.opencontainers.image.version="${BUILD_VERSION}"
LABEL org.opencontainers.image.revision="${SOURCE_SHA}"
LABEL org.opencontainers.image.created="${SOURCE_DATE}"
LABEL app.star.build-version="${BUILD_VERSION}"

WORKDIR /usr/local/bin

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

COPY --from=builder /usr/local/bin/star-admin /usr/local/bin/star-admin

ENV BUILD_VERSION="${BUILD_VERSION}"
ENV STAR_ADMIN_HOST="0.0.0.0"
ENV STAR_ADMIN_PORT="8080"

USER 65532:65532

EXPOSE 8080

CMD ["/usr/local/bin/star-admin"]
