#!/usr/bin/env python3
"""Publish a verified immutable GHCR image manifest to the metadata Release.

This script is intentionally shared by all Docker image jobs. It uses only the
Python standard library and the authenticated GitHub CLI.
"""
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ALLOWED_COMPONENTS = frozenset((
    "web-assets", "desktop-renderer", "mobile-builder", "server",
))


def make_manifest(component, commit, owner, digest, published_at=None):
    if component not in ALLOWED_COMPONENTS:
        raise ValueError("Unsupported Docker component")
    if not re.fullmatch(r"[a-fA-F0-9]{40}", commit):
        raise ValueError("A complete 40-character commit SHA is required")
    if not re.fullmatch(r"[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?", owner):
        raise ValueError("Invalid GitHub repository owner")
    if not re.fullmatch(r"sha256:[a-fA-F0-9]{64}", digest):
        raise ValueError("Invalid OCI digest")
    name = f"ghcr.io/{owner.lower()}/star-{component}"
    tag = f"sha-{commit[:7]}"
    timestamp = published_at or datetime.now(timezone.utc).strftime(
        "%Y-%m-%dT%H:%M:%SZ"
    )
    return {
        "schema_version": 1,
        "component": component,
        "source_commit": commit.lower(),
        "platform": "linux/amd64",
        "published_at": timestamp,
        "registry": "ghcr.io",
        "image": name,
        "tag": f"{name}:{tag}",
        "digest": digest.lower(),
        "immutable_image": f"{name}@{digest.lower()}",
        "pull_command": f"docker pull {name}@{digest.lower()}",
    }


def github(*arguments):
    result = subprocess.run(
        ["gh", *arguments], check=True, capture_output=True, text=True
    )
    return result.stdout


def publish(manifest, repository):
    if not re.fullmatch(r"[a-zA-Z0-9-]+/[a-zA-Z0-9_.-]+", repository):
        raise ValueError("Invalid GitHub repository")
    commit = manifest["source_commit"]
    component = manifest["component"]
    tag = "star-meta-" + commit[:8]
    filename = f"star-{component}-{commit[:8]}.json"
    with tempfile.TemporaryDirectory(prefix="star-image-manifest-") as directory:
        path = Path(directory) / filename
        path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        github("release", "upload", tag, str(path), "--repo", repository, "--clobber")
        response = json.loads(github(
            "release", "view", tag, "--repo", repository, "--json", "assets"
        ))
        matching = [
            asset for asset in response.get("assets", [])
            if asset.get("name") == filename and asset.get("size", 0) > 0
        ]
        if len(matching) != 1:
            raise RuntimeError(f"Release {tag} does not contain valid {filename}")
    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as output:
            output.write(
                "### Published OCI image\n\n"
                f"- Component: {component}\n"
                f"- Image: {manifest['immutable_image']}\n"
                f"- Metadata Release: star-meta-{commit[:8]}\n"
                f"- Manifest verified: {filename}\n"
            )
    print(f"Verified {filename} in {tag}")


def main():
    for key in (
        "COMPONENT", "IMAGE_DIGEST", "GITHUB_SHA",
        "GITHUB_REPOSITORY_OWNER", "GH_REPO", "GH_TOKEN",
    ):
        if not os.environ.get(key):
            raise ValueError(f"Missing environment variable: {key}")
    expected_owner = os.environ["GH_REPO"].split("/", 1)[0]
    if expected_owner.lower() != os.environ["GITHUB_REPOSITORY_OWNER"].lower():
        raise ValueError("Repository owner mismatch")
    manifest = make_manifest(
        os.environ["COMPONENT"],
        os.environ["GITHUB_SHA"],
        os.environ["GITHUB_REPOSITORY_OWNER"],
        os.environ["IMAGE_DIGEST"],
    )
    publish(manifest, os.environ["GH_REPO"])


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"Image manifest publication failed: {error}", file=sys.stderr)
        sys.exit(1)
