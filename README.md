# Star

![Star brand: symbol and Cherry Bomb One wordmark](docs/brand/star-logo-badge.svg)

[![Build and release](https://github.com/ls-matheus/Star/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/ls-matheus/Star/actions/workflows/docker-publish.yml)
[![License: AGPL-3.0-or-later](https://img.shields.io/badge/license-AGPL--3.0--or--later-blue.svg)](LICENSE)

**Star is an experimental, open-source messaging stack** with a web client, an Electron desktop application, a Flutter mobile client, and a Rust-based server. The repository brings these components together with Docker tooling and an incremental GitHub Actions release pipeline.

> **Status: technical preview.** The downloadable applications are testing builds, not production-certified releases. Android currently publishes an ARM64 debug APK; Windows and macOS packages are x64 builds without commercial code signing or notarization. The self-hosting configuration is intended for local development, not a public internet deployment.

[Downloads](#downloads) · [Get started](#get-started) · [Architecture](docs/architecture.md) · [Build and release guide](docs/build-and-release.md) · [Brand identity](docs/brand/README.md) · [Português](docs/pt-BR/README.md)

## What's in the repository

Star is a multi-component source tree rather than a single application package.

| Directory | Technology | Purpose |
| --- | --- | --- |
| [`Star web/`](Star%20web/) | Rust, TypeScript, React, Electron | Web application, desktop shell, and shared frontend assets |
| [`Star mobile/`](Star%20mobile/) | Flutter, Dart, native Rust | Android and mobile application source |
| [`Star Server/`](Star%20Server/) | Rust, supporting services | Monolithic server and self-hosting runtime |
| [`Docker/`](Docker/) | Docker, Compose, Bash, Python | Local environment, image builds, release scripts, and regression tests |
| [`.github/workflows/`](.github/workflows/) | GitHub Actions | One workflow for validation, component builds, packaging, and publishing |
| [`docs/`](docs/) | Markdown | Architecture, release procedures, and engineering notes |

**Source synchronization:** `Star web/` and `Star Server/` contain separate snapshots of overlapping monorepo code. Updating one does not update the other automatically. See [architecture and known risks](docs/architecture.md).

## Downloads

Use the [Releases page](https://github.com/ls-matheus/Star/releases) to select the latest available technical build. The [v0.0.8 artifact release](https://github.com/ls-matheus/Star/releases/tag/star-build-df8b6e0e) is the existing reference build.

| Platform | Available format | Current scope |
| --- | --- | --- |
| Android | `Star-Android-ARM64-DEBUG.apk` | ARM64 debug build, not signed for Play Store distribution |
| Windows | `Star-*-win-x64.exe` | x64 installer, without commercial code signing |
| macOS | `Star-*-mac-x64.dmg` and `.zip` | Intel x64, without Apple notarization |
| Docker | Compressed `.docker.tar.zst` image or numbered parts | Linux/AMD64 images; download all parts and verify checksums |
| iOS | No release asset | Source exists; no iOS binary is built by this pipeline |

A source commit can have **two separate prereleases**:

- **Artifacts** (`star-build-<commit>`): APK, EXE, DMG, ZIP, and downloadable Docker image archives.
- **JSONs and metadata** (`star-meta-<commit>`): immutable OCI digests, provenance manifests, and the incremental build baseline.

Each changed component publishes independently when its build and upload finish. Unchanged binaries are reused by links to their original Releases rather than uploaded again.

See [how releases work](docs/build-and-release.md) before downloading Docker archives or interpreting build statuses.

## Get started

### Run the server locally with Docker

Install a compatible Docker Engine and Compose plugin, then run:

```bash
git clone https://github.com/ls-matheus/Star.git
cd Star/Docker
cp .env.example .env
./star.sh doctor
./star.sh up
./star.sh status
```

If the container finishes starting and becomes healthy, open **http://localhost:8080** on the same computer. Stop it using `./star.sh down`; this preserves the named data volume.

The sample Compose configuration binds the web port to `127.0.0.1`. Do **not** expose this development configuration directly to the internet. Use real TLS, credentials, network controls, and backups for any non-local deployment.

For configuration and troubleshooting, see the [Docker guide](Docker/README.md).

### Work on the source code

Start with the source-specific documentation and manifests:

- [Web and desktop source guide](Star%20web/README.md) — `package.json`, `pnpm-workspace.yaml`, and Rust workspaces.
- [Mobile source guide](Star%20mobile/README.md) — `pubspec.yaml`, Flutter packages, and native build requirements.
- [Server source and packaging](Star%20Server/README.md) — server code and `packaging/monolith/Dockerfile`.

**Documentation caveat:** Some inherited READMEs inside the component snapshots refer to placeholder `*.invalid` domains or publication channels not configured for this repository. Treat **this README and this repository's Releases** as the current source for downloads and supported builds.

## Build, test, and release

The repository uses a single workflow: [**Star | Build and release**](https://github.com/ls-matheus/Star/actions/workflows/docker-publish.yml).

Run the lightweight validation and incremental planner without compiling applications:

```bash
gh workflow run docker-publish.yml --repo ls-matheus/Star -f target=plan
```

To run the local CI regression suite:

```bash
python3 -m unittest discover -s Docker/tests -p 'test_*.py' -v
```

Other manual workflow targets include `apps`, `server`, `all`, and `backfill`. Set `force_rebuild=true` only when a full rebuild of the selected scope is required. The workflow reuses cached Docker layers and immutable Release references for unchanged components.

For deployment artifacts, release naming, checksums, and troubleshooting, see the [build and release guide](docs/build-and-release.md).

## Project status and limitations

This repository provides repeatable build and publication tooling, but **successful compilation is not an end-to-end quality or security certification**. Installation tests across supported devices, store signing, macOS notarization, production TLS, and public-server hardening require separate validation. See the [engineering audit](docs/engineering-audit.md) for the current risks and follow-up work.

## Commercial distribution and upstream rights

Star is an independent, modified distribution of software associated with Fluxer and its Flutter client. It is **not affiliated with or endorsed by Fluxer Platform AB**. The AGPL-licensed source, CC BY-SA-licensed artwork, and other third-party materials have separate compliance requirements. A Star filename or new logo does not by itself establish that an asset is independently owned.

**Not cleared for unrestricted commercial distribution:** read the [commercial compliance audit and release gate](docs/commercial-compliance.md) before selling binaries or offering a public hosted service. The checklist includes corresponding source offers, in-app notices, brand provenance, and third-party licenses. This repository does not claim legal certification or blanket trademark permission.

## Contributing and security

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.
- Open regular bugs or feature requests in [GitHub Issues](https://github.com/ls-matheus/Star/issues).
- Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md). Never post credentials, tokens, or exploit details in public issues.

## License and attribution

The source is distributed under the [GNU Affero General Public License v3](LICENSE) (AGPLv3), with component-specific notices and exceptions where applicable. The source trees document upstream origins associated with the [Fluxer project](https://github.com/fluxerapp/fluxer); see [NOTICE.md](NOTICE.md) and the individual component licenses before redistribution.

Maintained at [ls-matheus/Star](https://github.com/ls-matheus/Star).
