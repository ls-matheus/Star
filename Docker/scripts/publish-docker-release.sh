#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Exports the exact immutable GHCR image to a downloadable GitHub Release asset.
# Split files stay below GitHub's 2 GiB/asset limit.
set -euo pipefail

: "${COMPONENT:?Missing Docker component name}"
: "${GITHUB_SHA:?Missing GITHUB_SHA}"
: "${GITHUB_REPOSITORY_OWNER:?Missing GITHUB_REPOSITORY_OWNER}"
: "${GH_TOKEN:?Missing GH_TOKEN}"
: "${GH_REPO:?Missing GH_REPO}"
: "${RUNNER_TEMP:?Missing RUNNER_TEMP}"

case "$COMPONENT" in
  server|web-assets|desktop-renderer|mobile-builder) ;;
  *) echo "Unsupported component: $COMPONENT" >&2; exit 2 ;;
esac

if ! command -v zstd >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends zstd
fi

# Archive jobs do not need preinstalled Android, .NET or CodeQL toolchains.
# Reclaim disk space for image layers and compressed Release assets.
if [[ "${CI:-}" == 'true' ]]; then
  sudo rm -rf /usr/local/lib/android /usr/share/dotnet /opt/hostedtoolcache/CodeQL 2>/dev/null || true
  df -h /
fi

requested_sha="${RELEASE_SHA:-$GITHUB_SHA}"
sha8="${requested_sha:0:8}"
sha7="${requested_sha:0:7}"
release="star-build-${sha8}"
prefix="star-${COMPONENT}-${sha8}"
out="${RUNNER_TEMP}/star-release-${COMPONENT}"
mkdir -p "$out"

# New builds keep JSON metadata in its own Release. Old Releases may still
# have the manifest in the artifacts tag until migration is complete.
metadata_release="star-meta-${sha8}"
if gh release view "$metadata_release" >/dev/null 2>&1; then
  source_release="$metadata_release"
else
  source_release="$release"
fi
gh release download "$source_release" --pattern "${prefix}.json" --dir "$out" --clobber
manifest="$out/${prefix}.json"
test -s "$manifest"

image="$(jq -er '.immutable_image' "$manifest")"
owner_lower="$(printf '%s' "$GITHUB_REPOSITORY_OWNER" | tr '[:upper:]' '[:lower:]')"
expected="ghcr.io/${owner_lower}/star-${COMPONENT}@sha256:"
if [[ "$image" != "$expected"* ]] || [[ ! "$image" =~ sha256:[[:xdigit:]]{64}$ ]]; then
  echo "Unexpected immutable image reference: $image" >&2
  exit 2
fi

echo "Downloading immutable image $image"
docker pull --platform linux/amd64 "$image"
tagged="ghcr.io/${owner_lower}/star-${COMPONENT}:sha-${sha7}"
docker tag "$image" "$tagged"

# Stream compression to disk; never materialize an enormous uncompressed tar.
# A 1,400 MiB chunk stays below the GitHub Releases per-file 2 GiB limit.
base="${prefix}.docker.tar.zst"
echo "Exporting image to $base (split when needed)"
docker save "$tagged" |
  zstd --threads=2 --compress -3 --stdout |
  split -b 1400m - "$out/${base}.part-"

shopt -s nullglob
parts=("$out/${base}.part-"*)
if (( ${#parts[@]} == 0 )); then
  echo "Docker export unexpectedly produced no archive" >&2
  exit 1
fi
if (( ${#parts[@]} == 1 )); then
  mv "${parts[0]}" "$out/$base"
  parts=("$out/$base")
fi

checksums="$out/${prefix}.docker.sha256"
instructions="$out/${prefix}.docker.README.txt"
(
  cd "$out"
  for part in "${parts[@]}"; do
    sha256sum "$(basename "$part")"
  done > "$checksums"
)
cat > "$instructions" <<EOF
Star Docker image archive for component: $COMPONENT
Source commit: $requested_sha
Immutable image: $image

Recommended online installation:
  docker pull "$image"

Offline installation from this GitHub Release:
  Download all the matching .docker.tar.zst or .part-* assets.
  Check integrity using: sha256sum -c "$(basename "$checksums")"
EOF

if (( ${#parts[@]} == 1 )); then
  echo "  zstd -dc '$base' | docker load" >> "$instructions"
else
  echo "  cat '$base'.part-* | zstd -dc | docker load" >> "$instructions"
fi

echo "Image parts and sizes:"
du -h "${parts[@]}"
echo "Uploading archive contents to release $release"
for file in "${parts[@]}" "$checksums" "$instructions"; do
  uploaded=false
  for attempt in 1 2 3; do
    if gh release upload "$release" "$file" --clobber; then
      uploaded=true
      break
    fi
    echo "Release upload attempt $attempt failed for $(basename "$file")" >&2
    sleep $((attempt * 8))
  done
  [[ "$uploaded" == 'true' ]] || exit 1
done

published="$(gh release view "$release" --json assets --jq '.assets[].name')"
for path in "${parts[@]}" "$checksums" "$instructions"; do
  if ! grep -Fxq "$(basename "$path")" <<< "$published"; then
    echo "Release upload verification failed for $(basename "$path")" >&2
    exit 1
  fi
done
{
  echo "Docker archive published in Release $release: $COMPONENT"
  printf 'Parts: %s\n' "${#parts[@]}"
  echo "Image: $image"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
