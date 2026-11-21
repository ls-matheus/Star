#!/usr/bin/env python3
"""Star component-level CI cache. Immutable GHCR digests and Release assets.

The cache is a JSON manifest in a JSON-only GitHub Release, not an Actions run.
If cache discovery or validation fails, the planner rebuilds the affected code.
Never treats a compiled APK, DMG or EXE as a source-level incremental cache.
"""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

SCHEMA = 1
CACHE_NAME = "star-incremental-base.json"
COMPONENTS = ("web", "desktop", "mobile", "server", "apk", "mac", "windows")
IMAGE_NAMES = {"web": "web-assets", "desktop": "desktop-renderer",
               "mobile": "mobile-builder", "server": "server"}
APP_COMPONENTS = ("web", "desktop", "mobile", "apk", "mac", "windows")
REPO = os.environ.get("GH_REPO", "ls-matheus/Star")
HEAD = os.environ.get("GITHUB_SHA", "").strip()
# Increment this if build toolchain flags or dependency mapping change.
CACHE_RULES_VERSION = "star-incremental-v1"


def sh(*argv, check=True, env=None):
    result = subprocess.run(argv, capture_output=True, text=True, env=env)
    if check and result.returncode:
        raise RuntimeError(f"{' '.join(map(str, argv))}: {result.stderr[-1400:]}")
    return result


def gh(*argv, check=True):
    return sh("gh", *argv, check=check)


def api(path):
    return json.loads(gh("api", path).stdout)


def git_blob(commit, path):
    result = sh("git", "rev-parse", f"{commit}:{path}", check=False)
    if result.returncode:
        return "missing"
    value = result.stdout.strip()
    if not re.fullmatch(r"[0-9a-f]{40,64}", value):
        raise ValueError(f"Bad git object id for {path}: {value}")
    return value


def fingerprint(commit):
    # Image context fingerprints stay independent of release notes and CI scripts.
    web = git_blob(commit, "Star web")
    mobile = git_blob(commit, "Star mobile")
    server = git_blob(commit, "Star Server")
    builder = [
        git_blob(commit, "Docker/Dockerfile.mobile"),
        git_blob(commit, "Docker/scripts/build-android.sh"),
    ]
    packaging = git_blob(commit, ".github/workflows/star-electron-builder.cjs")

    def h(label, *values):
        encoded = json.dumps([CACHE_RULES_VERSION, label, *values],
                             separators=(",", ":"), ensure_ascii=False).encode()
        return hashlib.sha256(encoded).hexdigest()

    return {
        "web": h("web", web),
        "desktop": h("desktop", web),
        "mobile": h("mobile-builder", *builder),
        "server": h("server", server),
        "apk": h("apk", web, mobile, *builder),
        "mac": h("macos-installer", web, packaging),
        "windows": h("windows-installer", web, packaging),
    }


def get_releases():
    return api(f"repos/{REPO}/releases?per_page=100")


def release_info(tag):
    return json.loads(gh("release", "view", tag, "-R", REPO, "--json",
                         "tagName,assets,body").stdout)


def asset_names(tag):
    return [a["name"] for a in release_info(tag)["assets"]]


def download(tag, pattern, directory):
    gh("release", "download", tag, "-R", REPO,
       "--pattern", pattern, "--dir", str(directory), "--clobber")
    return Path(directory) / pattern


def upload_json(tag, filename, data):
    with tempfile.TemporaryDirectory(prefix="star-upload-") as directory:
        output = Path(directory) / filename
        output.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
        gh("release", "upload", tag, str(output), "-R", REPO, "--clobber")
    if filename not in asset_names(tag):
        raise RuntimeError(f"Missing published {filename} in {tag}")


def validates_cache(cache, current_sha):
    if cache.get("schema") != SCHEMA or cache.get("repository") != REPO:
        return False
    origin = cache.get("commit", "")
    if not re.fullmatch(r"[a-f0-9]{40}", origin):
        return False
    if sh("git", "merge-base", "--is-ancestor", origin, current_sha,
          check=False).returncode:
        return False
    return isinstance(cache.get("components"), dict)


def find_cache(current_sha, pinned_tag=""):
    if pinned_tag in ("none", "None"):
        return None, ""
    if pinned_tag:
        candidates = [r for r in get_releases() if r["tag_name"] == pinned_tag]
    else:
        candidates = get_releases()
    for rel in candidates:
        if not any(a["name"] == CACHE_NAME for a in rel.get("assets", [])):
            continue
        with tempfile.TemporaryDirectory(prefix="star-baseline-") as temp:
            try:
                p = download(rel["tag_name"], CACHE_NAME, temp)
                cache = json.loads(p.read_text())
                if validates_cache(cache, current_sha):
                    return cache, rel["tag_name"]
            except (RuntimeError, ValueError, json.JSONDecodeError, OSError) as error:
                print(f"Cache {rel['tag_name']} unusable: {error}", file=sys.stderr)
    return None, ""


def baseline_component(key, origin_commit, assets_tag, meta_tag, filenames, ref=""):
    fps = fingerprint(origin_commit)
    return {
        "fingerprint": fps[key],
        "source_commit": origin_commit,
        "artifact_release": assets_tag,
        "metadata_release": meta_tag,
        "assets": sorted(filenames),
        "image_ref": ref,
    }


def parse_immutable(tag, name, workspace):
    p = download(tag, name, workspace)
    data = json.loads(p.read_text())
    image = data.get("immutable_image", "")
    if not re.fullmatch(r"ghcr\.io/[a-z0-9_.-]+/star-[a-z0-9-]+@sha256:[a-f0-9]{64}", image):
        raise RuntimeError(f"Invalid immutable image in {tag}/{name}: {image}")
    return image


def seed(_args):
    # Seed from the latest complete, actually published Star installers.
    # No Docker image pull, download of installers or Action build required.
    sha8 = "df8b6e0e"
    origin = sh("git", "rev-parse", f"{sha8}^{{commit}}").stdout.strip()
    previous_server = sh("git", "rev-parse", "e7d1bebf^{commit}").stdout.strip()
    assets_tag = f"star-build-{sha8}"
    meta_tag = f"star-meta-{sha8}"
    names = asset_names(assets_tag)
    meta_names = asset_names(meta_tag)
    components = {}
    with tempfile.TemporaryDirectory(prefix="star-seed-") as temp:
        for kind, component in IMAGE_NAMES.items():
            base_sha = "e7d1bebf" if kind == "server" else sha8
            source = previous_server if kind == "server" else origin
            asset_rel = f"star-build-{base_sha}"
            meta_rel = asset_rel if kind == "server" else meta_tag
            manifest = f"star-{component}-{base_sha}.json"
            if manifest not in asset_names(meta_rel):
                raise RuntimeError(f"Cannot seed absent image {manifest} in {meta_rel}")
            image_ref = parse_immutable(meta_rel, manifest, temp)
            binary_names = [
                n for n in asset_names(asset_rel)
                if n.startswith(f"star-{component}-{base_sha}.docker.")
            ]
            components[kind] = baseline_component(
                kind, source, asset_rel, meta_rel, binary_names, image_ref)
        for kind, select in {
            "apk": lambda n: n.lower().endswith(".apk"),
            "mac": lambda n: n.lower().endswith((".dmg", ".zip")),
            "windows": lambda n: n.lower().endswith(".exe"),
        }.items():
            matching = [n for n in names if select(n)]
            if not matching:
                raise RuntimeError(f"Cannot seed missing {kind} installer")
            components[kind] = baseline_component(kind, origin, assets_tag,
                                                  meta_tag, matching)

    manifest = {
        "schema": SCHEMA, "repository": REPO, "commit": origin,
        "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "purpose": "Incremental input fingerprints and immutable build origins",
        "components": components,
    }
    if os.environ.get("DRY_RUN") == "1":
        print(json.dumps(manifest, indent=2))
        return
    upload_json(meta_tag, CACHE_NAME, manifest)
    print(f"Seeded {len(components)} components in {meta_tag}")
    for key, value in components.items():
        print(f"  {key}: {value['source_commit'][:8]} | {len(value['assets'])} archived files")
    print("No binaries copied or rebuilt.")


def normalized_baseline(cache, key):
    item = (cache or {}).get("components", {}).get(key) or {}
    if not isinstance(item, dict) or not re.fullmatch(
            r"[a-f0-9]{64}", str(item.get("fingerprint", ""))):
        return {}
    if key in IMAGE_NAMES and not re.fullmatch(
            r"ghcr\.io/[a-z0-9_.-]+/star-[a-z0-9-]+@sha256:[a-f0-9]{64}",
            str(item.get("image_ref", ""))):
        return {}
    if key in ("apk", "mac", "windows") and not item.get("assets"):
        return {}
    if not item.get("artifact_release") or not item.get("metadata_release"):
        return {}
    return item


def plan(_args):
    if not HEAD:
        raise RuntimeError("GITHUB_SHA required")
    actual = fingerprint(HEAD)
    cache, baseline_tag = find_cache(HEAD)
    selected = os.environ.get("STAR_TARGET", "apps")
    event = os.environ.get("GITHUB_EVENT_NAME", "push")
    force = os.environ.get("STAR_FORCE_REBUILD", "").lower() == "true"

    if selected == "backfill":
        apps_scope, server_scope = False, False
    elif event == "workflow_dispatch":
        apps_scope = selected in ("apps", "all", "plan")
        server_scope = selected in ("server", "all", "plan")
    else:
        apps_scope = True
        server_scope = True if cache else False
        if not cache:
            # Without a cache, avoid an unrelated Server build on an app-only push.
            before = os.environ.get("STAR_BEFORE", "").strip()
            if re.fullmatch(r"[a-f0-9]{40}", before) and before != "0"*40:
                changes = sh("git", "diff", "--name-only", before, HEAD).stdout
                server_scope = any(n.startswith("Star Server/") for n in changes.splitlines())
            else:
                server_scope = True

    builds = {}
    for key in COMPONENTS:
        base = normalized_baseline(cache, key)
        scope = server_scope if key == "server" else apps_scope
        builds[key] = bool(scope and (force or not base or base["fingerprint"] != actual[key]))
    # A builder/renderer change invalidates compiled downstream installers.
    if builds["mobile"] and apps_scope:
        builds["apk"] = True
    if builds["desktop"] and apps_scope:
        builds["mac"] = True
        builds["windows"] = True
    renderer_cached = (not builds["desktop"] and
                       (builds["mac"] or builds["windows"]))
    image_ref = {
        key: (f"ghcr.io/{REPO.lower()}/star-{IMAGE_NAMES[key]}:"
              f"sha-{HEAD[:7]}" if builds[key] else
              normalized_baseline(cache, key).get("image_ref", ""))
        for key in IMAGE_NAMES
    }
    if renderer_cached and not image_ref["desktop"]:
        raise RuntimeError("Renderer cache needed but its immutable GHCR digest is missing")
    if builds["apk"] and not image_ref["mobile"]:
        raise RuntimeError("APK build needed but Mobile Builder reference is missing")

    outputs = {f"build_{key}": str(builds[key]).lower() for key in COMPONENTS}
    outputs.update({
        "desktop_cache": str(renderer_cached).lower(),
        "mobile_image_ref": image_ref["mobile"],
        "desktop_image_ref": image_ref["desktop"],
        "base_tag": baseline_tag or "none",
        "apps": str(apps_scope).lower(), "server": str(server_scope).lower(),
    })
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a") as file:
            for key, value in outputs.items():
                file.write(f"{key}={value}\n")
    print("Incremental baseline:", baseline_tag or "NOT FOUND: rebuilding", flush=True)
    summary = [
        "## Star | Plano incremental", "",
        f"- Baseline: \`{baseline_tag or 'nenhuma; fallback seguro'}\`",
        f"- Forcar rebuild: \`{force}\`", "",
        "| Componente | Ação |",
        "| --- | --- |",
    ]
    for key in COMPONENTS:
        status = "compilar" if builds[key] else (
            "reutilizar" if normalized_baseline(cache, key) else "fora do escopo")
        summary.append(f"| {key} | **{status}** |")
        print(f"  {key:8} => {status}, current={actual[key][:12]}")
    summary.append(f"\nRenderer reutilizado nos jobs nativos: {renderer_cached}\n")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
            f.write("\n".join(summary) + "\n")


def finalize(_args):
    if not HEAD:
        raise RuntimeError("GITHUB_SHA required")
    base_tag = os.environ.get("STAR_BASE_TAG", "")
    baseline, _ = find_cache(HEAD, base_tag)
    current = fingerprint(HEAD)
    sha8 = HEAD[:8]
    art_tag = f"star-build-{sha8}"
    meta_tag = f"star-meta-{sha8}"
    art_names = asset_names(art_tag)
    meta_names = asset_names(meta_tag)
    components = {}
    with tempfile.TemporaryDirectory(prefix="star-final-") as temp:
        for key in COMPONENTS:
            built = os.environ.get(f"STAR_BUILT_{key.upper()}", "false") == "true"
            if built:
                if key in IMAGE_NAMES:
                    component = IMAGE_NAMES[key]
                    manifest = f"star-{component}-{sha8}.json"
                    if manifest not in meta_names:
                        raise RuntimeError(f"Missing image JSON from new build: {manifest}")
                    image = parse_immutable(meta_tag, manifest, temp)
                    archives = [
                        n for n in art_names
                        if n.startswith(f"star-{component}-{sha8}.docker.")
                    ]
                    # Verify exporter finished; must have at least one image part.
                    if not any(".docker.tar.zst" in n for n in archives):
                        raise RuntimeError(f"Missing Docker export for {component}")
                    components[key] = baseline_component(
                        key, HEAD, art_tag, meta_tag, archives, image)
                else:
                    filters = {
                        "apk": lambda n: n.lower().endswith(".apk"),
                        "mac": lambda n: n.lower().endswith((".dmg", ".zip")),
                        "windows": lambda n: n.lower().endswith(".exe"),
                    }
                    matches = [n for n in art_names if filters[key](n)]
                    if not matches:
                        raise RuntimeError(f"Missing new installer: {key}")
                    components[key] = baseline_component(
                        key, HEAD, art_tag, meta_tag, matches)
            else:
                previous = normalized_baseline(baseline, key)
                if previous and previous.get("fingerprint") == current[key]:
                    components[key] = previous
                elif key == "server" and previous and (
                      os.environ.get("STAR_SCOPE_SERVER") == "false"):
                    # Manual apps mode: retain historical server cache unchanged.
                    components[key] = previous
                elif key in APP_COMPONENTS and previous and (
                      os.environ.get("STAR_SCOPE_APPS") == "false"):
                    # Manual server mode: preserve historical apps as-is.
                    components[key] = previous
                elif previous and os.environ.get("STAR_SKIP_REASON") == "backfill":
                    components[key] = previous
                else:
                    raise RuntimeError(f"Invalid reused cache component {key}; "
                                       "refusing to record an unbuilt fingerprint")
    record = {
        "schema": SCHEMA, "repository": REPO, "commit": HEAD,
        "base_commit": (baseline or {}).get("commit"),
        "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "purpose": "Incremental input fingerprints and immutable build origins",
        "components": components,
    }

    # Every requested release is linkable even when large binaries are reused
    # by reference rather than needlessly transferring multi-GB archives.
    for tag, is_metadata in ((art_tag, False), (meta_tag, True)):
        rel = release_info(tag)
        text = rel.get("body", "").split("\n## Reutilizacao incremental\n")[0]
        reused = []
        for key, item in components.items():
            if item.get("source_commit") == HEAD:
                continue
            origin = item["metadata_release"] if is_metadata else item["artifact_release"]
            assets = [f"[{n}](https://github.com/{REPO}/releases/download/{origin}/{n})"
                      for n in item.get("assets", [])]
            if is_metadata:
                if key not in IMAGE_NAMES:
                    continue
                comp = IMAGE_NAMES[key]
                origin = item["metadata_release"]
                name = f"star-{comp}-{item['source_commit'][:8]}.json"
                assets = [f"[{name}](https://github.com/{REPO}/releases/download/{origin}/{name})"]
            if assets:
                reused.append(f"| {key} | {item['source_commit'][:8]} | " +
                              ", ".join(assets) + " |")
        if reused:
            text += ("\n## Reutilizacao incremental\n\n"
                     "Os itens abaixo nao foram recompilados nem duplicados nesta Release. "
                     "Os links levam aos binarios/JSONs identicos, preservados nas Releases "
                     "de origem.\n\n"
                     "| Componente | Build de origem | Arquivos reutilizados |\n"
                     "| --- | --- | --- |\n" + "\n".join(reused) + "\n")
        with tempfile.TemporaryDirectory(prefix="star-notes-") as nd:
            p = Path(nd) / "notes.md"
            p.write_text(text + "\n")
            gh("release", "edit", tag, "-R", REPO, "--notes-file", str(p),
               "--prerelease")

    upload_json(meta_tag, CACHE_NAME, record)
    print(f"Incremental baseline recorded in {meta_tag} for {len(components)} components")
    print("Previously built binaries referenced in Release notes, not rebuilt.")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
            f.write("## Base incremental atualizada\n\n")
            f.write(f"- Commit: \`{HEAD[:8]}\`\n- Manifesto: \`{meta_tag}/{CACHE_NAME}\`\n")
            f.write("- Artefatos sem mudancas: links para Releases anteriores, sem download/reupload.\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("seed", "plan", "finalize", "fingerprints"))
    parser.add_argument("--commit", default=HEAD)
    args = parser.parse_args()
    if args.command == "seed":
        seed(args)
    elif args.command == "plan":
        plan(args)
    elif args.command == "finalize":
        finalize(args)
    else:
        print(json.dumps(fingerprint(args.commit), indent=2))


if __name__ == "__main__":
    main()
