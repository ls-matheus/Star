# Engineering audit

This document records the codebase and CI/CD review used to improve the repository's entry point and release documentation. It separates **observed facts**, **changes made**, and **work not yet verified**.

## Scope and evidence

Reviewed sources:

- Root Git tree and directory layout of the public `ls-matheus/Star` repository.
- Primary Web, Mobile, and Server source READMEs and build manifests.
- `Docker/` scripts, Compose configuration, and the Android Builder Dockerfile.
- The single `.github/workflows/docker-publish.yml` workflow and its publisher scripts.
- Existing GitHub Releases and OCI metadata relevant to artifact publication.
- Automated Python regression tests in `Docker/tests/`, YAML/actionlint checks, and shell syntax checks.

This is a **targeted structural and CI audit**, not a line-by-line audit of every application source file. No claim is made that a complete messaging session, installer lifecycle, or public server deployment has been tested by this document.

## Confirmed findings

### Repository presentation

**Observed:** No root `README.md` or root `LICENSE` existed in the integrated Git tree, and the GitHub repository's public description and topic list were empty.

**Addressed:** Added a concise root README, AGPL license text, source provenance, contribution and security guidance, and linked architecture/release documents. GitHub metadata is maintained separately from the source files.

### Duplicated source snapshots

**Observed:** The tracked inventory contains 39,844 files: 16,579 under `Star web/`, 16,579 under `Star Server/`, and 6,669 under `Star mobile/`. A Git tree-to-tree comparison at commit `a4be8a8` found just **four differing paths** between the Web and Server snapshots: `.gitattributes`, `LEIA-ME-STAR.md`, `star_app_proxy/Dockerfile`, and the generated desktop icon. The two `Cargo.lock` files are **identical** (Git blob `36bc1d6e1b7e`...).

**Remaining risk:** Changes in one snapshot do not automatically reach the other. Even a small divergence may matter for builds or packaging. Establish a versioned synchronization strategy before considering a production server.

### Inherited documentation links

**Observed:** Component READMEs reference `star.invalid`, `docs.star.invalid`, third-party download channels, and older repository paths.

**Addressed:** The root README links to actual Releases in this repository and explicitly identifies inherited placeholder documentation. **Remaining:** review and replace upstream placeholders only when real public domains and product distribution channels exist. Do not invent a site or store listing.

### Repeated CI publication logic

**Observed:** The four image jobs independently assembled the same OCI metadata JSON and included shell-formatted summaries with unescaped command-substitution delimiters.

**Addressed:** Moved manifest validation, serialization, upload and verification to a single shared Python publisher. Added regression tests for the manifest schema, invalid digests, a single workflow entry point, and SHA-pinned external Actions.

### Action dependency integrity

**Observed:** Several native platform, caching and artifact Actions used movable version/branch references rather than immutable commit SHAs.

**Addressed:** Resolved the existing action tags/branch to full verified Git commits and pinned those references. Per-job minimum permissions remain configured. Every future Action update should include a deliberate SHA and compatibility review.

### Test coverage and release readiness

**Observed:** CI validation covered shell syntax, Compose configuration, and the incremental build planner, while app packaging builds target macOS, Windows, and Android separately. Published binaries do not establish end-to-end application functionality.

**Addressed:** Added repository, documentation and manifest contract checks to the validation suite.

**Remaining:** Perform device installation and runtime checks, authentication/messaging/voice integration tests, secret scanning, dependency/security review, and store-signing/notarization before production distribution.

## Current operational constraints

| Area | Verified behavior or known limit |
| --- | --- |
| Local Server | Development Compose binds web traffic to `127.0.0.1`; not a hardened public deployment |
| Android | ARM64 debug APK; not store-signed |
| Windows | x64 EXE; commercial code signing not configured |
| macOS | Intel x64 DMG/ZIP; Apple notarization not configured |
| iOS | Mobile source exists; no IPA release job |
| Docker images | Linux/AMD64 images and compressed archives when built |
| Releases | Separate Artifacts and JSON/metadata prereleases; incremental references may point to previous Releases |
| CI | Single workflow with component-level planning, reusable cache, validation, and independent publish jobs |

## Prioritized follow-up work

1. **Production security:** decide the supported hosting topology, then add TLS, firewall, abuse controls, secret management, backup/restore tests, and operational monitoring.
2. **Application quality:** add representative end-to-end tests for Android, Windows, macOS and live Server interactions.
3. **Supply chain:** establish signing/notarization, dependency scanning, SBOM/provenance verification, and repeatable clean builds.
4. **Source ownership:** document and automate synchronization of the Web/Server snapshots; audit their Cargo lockfiles for drift when updating either tree.
5. **Release policy:** specify stable versioning, compatibility commitments, reproducibility expectations, and formal acceptance criteria.
6. **Placeholder cleanup:** correct inherited `*.invalid` links when authentic public destinations exist.

## Review approach

The process follows the public [Superpowers development methodology](https://github.com/obra/superpowers/tree/main/skills): investigate the actual source and failure first, add a regression test that exposes a defect, implement a scoped fix, and verify before claiming success. Documentation structure follows the public [Google README guidance](https://google.github.io/styleguide/docguide/READMEs.html) for purpose, audience, usage, status, and links.

Neither reference implies endorsement by the referenced organizations.

## How to reproduce the documentation and CI checks

From the repository root:

```bash
python3 -m unittest discover -s Docker/tests -p 'test_*.py' -v
bash -n Docker/scripts/build-android.sh
bash -n Docker/scripts/prepare-releases.sh
bash -n Docker/scripts/publish-docker-release.sh
actionlint .github/workflows/docker-publish.yml
```

`actionlint` is a separate developer tool. For full CI verification, use the `plan` target described in the [build and release guide](build-and-release.md). A plan-only run does not prove native packaging or runtime deployment.
