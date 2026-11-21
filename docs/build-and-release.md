# Build and release guide

This guide documents the Star release workflow, supported operations, and artifact provenance. The workflow is a **technical build pipeline**, not a production deployment or software-signing service.

## Workflow overview

The repository keeps one active entry point: [`Star | Build and release`](../.github/workflows/docker-publish.yml). The workflow validates sources and runs independent jobs only for affected components.

| Workflow mode | Entry point | Effect |
| --- | --- | --- |
| Automatic | Push to `main` affecting source or build files | Validate, plan, build affected components, publish, and update the cache baseline |
| Pull request | Changes in watched paths | Validate source/configuration and run regression tests, without publishing |
| `plan` | Manual dispatch | Run only validation and build-scope analysis; create no Release |
| `apps` | Manual dispatch | Evaluate and build changed client components |
| `server` | Manual dispatch | Evaluate and build the Server component |
| `all` | Manual dispatch | Evaluate client and Server components |
| `backfill` | Manual dispatch with `release_sha` | Export existing Web, Desktop, and Mobile Builder OCI images to an existing Release, without rebuilding |

To force an image or installer to rebuild, manually select the desired scope and pass `force_rebuild=true`. The workflow does not automatically perform expensive rebuilds for purely documentation changes.

## Run a validation-only check

Use the GitHub CLI with a session authorized for this repository:

```bash
gh workflow run docker-publish.yml \
  --repo ls-matheus/Star \
  --ref main \
  -f target=plan
```

Inspect the results on the [Actions page](https://github.com/ls-matheus/Star/actions/workflows/docker-publish.yml). Only the validation and planning jobs should run; no build images or Releases should be created.

To validate locally without Docker Engine:

```bash
python3 -m unittest discover -s Docker/tests -p 'test_*.py' -v
bash -n Docker/scripts/build-android.sh
bash -n Docker/scripts/prepare-releases.sh
bash -n Docker/scripts/publish-docker-release.sh
```

If you have [actionlint](https://github.com/rhysd/actionlint) installed, validate the workflow with:

```bash
actionlint .github/workflows/docker-publish.yml
```

These checks cannot replace an actual macOS, Windows, Android, or Docker build.

## Component-level incremental builds

The metadata Release contains `star-incremental-base.json`. It records source fingerprints, verified image digests, artifact origins, and immutable references for seven build components: Web, Desktop renderer, Mobile Builder, Server, APK, macOS, and Windows.

The initial baseline was captured from existing builds without recompilation. Each later successful run can publish a new baseline under its own metadata Release.

| Changed source | Recompiled components |
| --- | --- |
| `Star mobile/` source | APK only; reuse the Mobile Builder image |
| `Docker/Dockerfile.mobile` or `Docker/scripts/build-android.sh` | Mobile Builder image and APK |
| `Star web/` source | Web image, Desktop renderer, APK, macOS DMG/ZIP, Windows EXE |
| `Star Server/` source | Server OCI image only |
| Electron packager configuration | macOS and Windows installers, with a reused renderer |
| Documentation in the repository root | No application build |

A build is reused only when the planner finds a compatible baseline. If metadata is missing, invalid, or not an ancestor of the current commit, the planner schedules safe rebuilds for the selected scope.

**Unchanged binaries are not copied into a new Release.** New Release notes link to the original assets. Do not delete Releases whose assets are referenced by a later baseline.

The builds use GitHub Actions cache for Docker layers and selected dependencies. The existence of a cache improves potential performance but does not guarantee that every compiler step is skipped.

## Release structure

Each build commit uses the first eight characters of its Git SHA as its Release identifier.

| Release | Tag | Contents |
| --- | --- | --- |
| **Artifacts** | `star-build-<SHA8>` | New APK, EXE, DMG, ZIP, Docker compressed archives, checksums, and import instructions |
| **JSONs and metadata** | `star-meta-<SHA8>` | OCI image manifests, digests, and the incremental build baseline |

The two Releases are initialized early in the build. Jobs upload completed results independently, without waiting for the other platforms. A partial build may therefore show only a subset of files.

The [v0.0.8 Artifacts Release](https://github.com/ls-matheus/Star/releases/tag/star-build-df8b6e0e) and [v0.0.8 Metadata Release](https://github.com/ls-matheus/Star/releases/tag/star-meta-df8b6e0e) are examples.

### Image manifest fields

The publisher writes a validated JSON file for each image, with the component name, source SHA, platform, GHCR image, tag, SHA-256 digest, immutable image reference, and a `docker pull` command. The four image jobs share the same publisher script to avoid divergent schemas.

Retrieve manifest names directly from the metadata Release's **Assets** section. Reused manifests are referenced by a link to the earlier Release.

### Docker archive downloads

Download all files with the same image prefix from the artifacts Release. An image larger than GitHub's per-asset limit can be split into numbered parts.

For an unsplit archive:

```bash
sha256sum -c star-web-assets-<SHA8>.docker.sha256
zstd -dc star-web-assets-<SHA8>.docker.tar.zst | docker load
```

For a split archive, download **every** `.part-*` file first:

```bash
sha256sum -c star-mobile-builder-<SHA8>.docker.sha256
cat star-mobile-builder-<SHA8>.docker.tar.zst.part-* | zstd -dc | docker load
```

Replace `<SHA8>` with the Release identifier. The matching `.docker.README.txt` file contains import instructions and the immutable original reference. On systems without `sha256sum`, use a compatible SHA-256 verification tool.

Images are also available via GHCR with an immutable digest:

```bash
docker pull ghcr.io/ls-matheus/star-web-assets@sha256:<DIGEST>
```

Use the exact digest from the published JSON rather than the placeholder above.

## Platform-specific packaging

| Platform | Runner | Output | Distribution caveat |
| --- | --- | --- | --- |
| Android ARM64 | Linux container with Flutter, Rust, and Android SDK | DEBUG APK | Not store-signed or production approved |
| Windows x64 | Windows runner with Node, pnpm, Rust, and Electron | EXE | No commercial Authenticode signing |
| macOS Intel x64 | macOS Intel runner with Node, pnpm, Rust, and Electron | DMG and ZIP | No Developer ID notarization |
| Server/Web/Desktop/Mobile Builder | Linux/AMD64 OCI build | GHCR image and optional compressed archive | Development or integration artifacts, not hardened service deployment |

Native desktop packages use renderer assets extracted from the built or immutable cached Desktop image. They must be packaged on the target operating system because native Electron modules cannot be cross-compiled safely from a Linux container.

## Security and permissions

The workflow defaults to `contents: read` and grants elevated permissions only to jobs that publish images or Releases. External third-party Actions are pinned to verified full commit SHAs. Publishing uses the automatically provided `GITHUB_TOKEN`; do not add personal access tokens to the source tree.

`Docker/.env.example` documents local variables; `Docker/.env` is untracked, private configuration. Code signing keys, production credentials, and mobile store certificates must never be committed.

## Troubleshooting

If a build fails, identify the earliest failed job instead of changing several components at once.

1. Review the failed job's logs in [Actions](https://github.com/ls-matheus/Star/actions).
2. Check the incremental plan for the components marked to rebuild.
3. Verify the source commit, image manifest, and target Release tags.
4. Reproduce the failing stage locally when tools are available.
5. Run the repository regression suite and validation-only mode before retrying the full build.

A failed component does not remove assets already uploaded by other completed jobs. The final cache-baseline job runs only when its required outputs are healthy.

### Backfill an existing Docker Release

Select the `backfill` target and specify the existing Release's SHA identifier:

```bash
gh workflow run docker-publish.yml \
  --repo ls-matheus/Star \
  --ref main \
  -f target=backfill \
  -f release_sha=df8b6e0e
```

This operation does **not** build an application. It re-exports the images already published in GHCR for the selected commit. It currently covers Web Assets, Desktop Renderer, and Mobile Builder, not the Server.

## Related documents

- [Project README](../README.md)
- [Architecture](architecture.md)
- [Docker development guide](../Docker/README.md)
- [Engineering audit](engineering-audit.md)
- [Security policy](../SECURITY.md)
