#!/usr/bin/env python3
"""Static, non-destructive Star source integrity check. Not a build or E2E test."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
errors = []
warnings = []
for path in [
    ".gitignore", ".dockerignore", ".editorconfig", ".gitattributes",
    ".ignore", ".envrc", ".devcontainer/devcontainer.json",
    ".devcontainer/docker-compose.yml", "LICENSE", "README.md",
    "Cargo.toml", "Cargo.lock", "pnpm-workspace.yaml", "pnpm-lock.yaml", "config/env/development.example.env",
    "star_app/src", "star_api/src", "star_desktop", "star_gateway",
    "star_static/LICENSE",
]:
    if not (ROOT / path).exists():
        errors.append("Missing required path: " + path)

package_paths = [
    ROOT / "package.json",
    *ROOT.glob("packages/*/package.json"),
    *ROOT.glob("star_api/pkgs/*/package.json"),
    *ROOT.glob("star_app/pkgs/*/package.json"),
    *(ROOT / name / "package.json"
      for name in ["star_app", "star_api", "star_desktop", "star_docs", "star_admin"]),
]
packages = {}
manifests = {}
for p in package_paths:
    if not p.exists():
        continue
    try:
        info = json.loads(p.read_text(encoding="utf-8"))
    except (ValueError, OSError) as exc:
        errors.append(f"Invalid package JSON {p.relative_to(ROOT)}: {exc}")
        continue
    name = info.get("name")
    if not name:
        errors.append(f"Missing package name in {p.relative_to(ROOT)}")
    if name in packages:
        errors.append(f"Duplicate package name: {name}")
    packages[name] = p
    manifests[p] = info

for p, info in manifests.items():
    for section in ["dependencies", "devDependencies", "optionalDependencies", "peerDependencies"]:
        for name, version in info.get(section, {}).items():
            if isinstance(version, str) and version.startswith("workspace:") and name not in packages:
                errors.append(f"{p.relative_to(ROOT)}: unresolved workspace dependency {name}")
            if isinstance(version, str) and version.startswith("file:"):
                if not (p.parent / version[5:]).exists():
                    errors.append(f"{p.relative_to(ROOT)}: missing local dependency {name}")

cargo_paths = 0
for p in ROOT.rglob("Cargo.toml"):
    try:
        value = p.read_text(encoding="utf-8")
    except OSError:
        continue
    for target in re.findall(r'\bpath\s*=\s*["\']([^"\']+)["\']', value):
        cargo_paths += 1
        if not (p.parent / target).exists():
            errors.append(f"{p.relative_to(ROOT)}: invalid Cargo path {target}")

for filename in [ROOT / ".devcontainer/devcontainer.json", ROOT / ".vscode/extensions.json"]:
    if filename.exists():
        try:
            value = json.loads(filename.read_text(encoding="utf-8"))
            if filename.name == "devcontainer.json" and value.get("workspaceFolder") != "/workspaces/star":
                errors.append("Dev Container must point at /workspaces/star")
        except ValueError as exc:
            errors.append(f"Invalid JSON {filename.relative_to(ROOT)}: {exc}")

for filename in [ROOT / ".devcontainer/docker-compose.yml", ROOT / ".devcontainer/devcontainer.json"]:
    if filename.exists():
        text = filename.read_text(encoding="utf-8")
        for marker in ["fluxer_", "FLUXER_", "/workspaces/fluxer"]:
            if marker in text:
                errors.append(f"{filename.relative_to(ROOT)} contains old marker {marker}")

if (ROOT / ".git").exists():
    import subprocess
    result = subprocess.run(["git", "check-ignore", "-q", "config/env/development.env"], cwd=ROOT)
    if result.returncode != 0:
        errors.append("Private development.env must remain gitignored")
else:
    warnings.append("Git has not been initialized")

if (ROOT / "README.md").exists() and "star.example" in (ROOT / "README.md").read_text(encoding="utf-8"):
    warnings.append("star.example is a placeholder, not a public deployment domain")
print(f"Checked {len(manifests)} npm package manifests and {cargo_paths} Cargo local paths.")
for entry in warnings:
    print("WARNING:", entry)
for entry in errors[:100]:
    print("ERROR:", entry)
print("STAR_SOURCE_CHECK:", "FAIL" if errors else "PASS")
sys.exit(1 if errors else 0)
