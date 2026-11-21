"""Repository and release-publishing regression tests.

Run with python3 -m unittest discover -s Docker/tests -p 'test_*.py'.
"""
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from urllib.parse import unquote
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/docker-publish.yml"
PUBLISHER = ROOT / "Docker/scripts/publish-image-manifest.py"


class RepositoryQualityTests(unittest.TestCase):
    def test_root_readme_and_open_source_metadata(self):
        for relative_path in (
            "README.md", "LICENSE", "CONTRIBUTING.md", "SECURITY.md",
            "docs/architecture.md", "docs/build-and-release.md",
        ):
            with self.subTest(relative_path=relative_path):
                self.assertTrue((ROOT / relative_path).is_file(), relative_path)

    def test_workflow_has_single_entrypoint(self):
        files = sorted(x.name for x in (ROOT / ".github/workflows").glob("*.yml"))
        self.assertEqual(files, ["docker-publish.yml"])

    def test_all_external_actions_pinned_to_full_commit_sha(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        uses = re.findall(r"(?m)^\s+uses:\s+([^\s#]+)", workflow)
        self.assertTrue(uses)
        for action in uses:
            with self.subTest(action=action):
                self.assertRegex(action, r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)?@[a-f0-9]{40}$")

    def test_json_publisher_is_shared_by_all_images(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertEqual(workflow.count("run: python3 Docker/scripts/publish-image-manifest.py"), 4)
        self.assertEqual(workflow.count("jq -n"), 0)

    def test_pipeline_keeps_server_and_client_builds_independent(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        def job_body(name):
            match = re.search(
                r"(?ms)^  " + re.escape(name) +
                r":\n(.*?)(?=^  [a-z][a-z0-9-]*:\s*$|\Z)",
                workflow,
            )
            self.assertIsNotNone(match, name)
            return match.group(1)
        for component in ("web", "desktop", "mobile", "server"):
            job = job_body(f"{component}-image")
            self.assertIn("needs: [prepare-release, detect]", job)
            self.assertIn(f"needs.detect.outputs.build_{component}", job)
            self.assertNotIn("needs.server-image", job)
            self.assertIn("github.event_name != 'pull_request'", job)
        for component, job in (
            ("web", "archive-web-assets"),
            ("desktop", "archive-desktop-renderer"),
            ("mobile", "archive-mobile-builder"),
            ("server", "archive-server"),
        ):
            self.assertIn(
                f"needs.detect.outputs.build_{component}", job_body(job)
            )
        apk = job_body("apk")
        self.assertIn("needs: [detect, prepare-release, mobile-image]", apk)
        for job, key in (("dmg", "build_mac"), ("exe", "build_windows")):
            native = job_body(job)
            self.assertIn("needs.desktop-cache.result == 'success'", native)
            self.assertIn(f"needs.detect.outputs.{key}", native)
        self.assertIn("needs:", job_body("finalize-cache"))

    def test_readme_links_and_markdown_structure(self):
        docs = [
            ROOT / "README.md",
            ROOT / "AGENTS.md",
            ROOT / "CONTRIBUTING.md",
            ROOT / "SECURITY.md",
            ROOT / "NOTICE.md",
            *sorted((ROOT / "docs").rglob("*.md")),
        ]
        for doc in docs:
            with self.subTest(document=str(doc.relative_to(ROOT))):
                content = doc.read_text(encoding="utf-8")
                self.assertEqual(content.count(chr(96)*3) % 2, 0)
                self.assertTrue(content.startswith("# "), "H1 document title required")
                for raw in re.findall(r"\[[^\]]+\]\(([^)]+)\)", content):
                    if raw.startswith(("https://", "http://", "#", "mailto:")):
                        self.assertFalse(
                            raw.startswith(("http://star.invalid", "https://star.invalid")),
                            "Do not link to placeholder public domains",
                        )
                        continue
                    path = unquote(raw.split("#", 1)[0].split("?", 1)[0])
                    if not path:
                        continue
                    target = (doc.parent / path).resolve()
                    if target.exists():
                        continue
                    relative = target.relative_to(ROOT)
                    result = subprocess.run(
                        ["git", "ls-files", "--error-unmatch", str(relative)],
                        cwd=ROOT, capture_output=True, text=True
                    )
                    self.assertEqual(result.returncode, 0, f"Broken local link in {doc}: {raw}")

    def test_manifest_publisher_uploads_and_verifies_asset(self):
        spec = importlib.util.spec_from_file_location("star_publisher", PUBLISHER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        manifest = module.make_manifest(
            "desktop-renderer", "a"*40, "ls-matheus", "sha256:"+"b"*64,
            published_at="2026-11-21T12:00:00Z"
        )
        calls = []
        uploaded = {}
        def fake_gh(*args):
            calls.append(args)
            if args[:2] == ("release", "upload"):
                path = Path(args[3])
                uploaded.update(name=path.name, content=json.loads(path.read_text()))
                return ""
            if args[:2] == ("release", "view"):
                return json.dumps({"assets": [{"name": uploaded["name"], "size": 400}]})
            raise AssertionError(args)
        with tempfile.TemporaryDirectory() as temp, \
             patch.object(module, "github", side_effect=fake_gh), \
             patch.dict(os.environ, {"GITHUB_STEP_SUMMARY": str(Path(temp)/"summary.md")}):
            module.publish(manifest, "ls-matheus/Star")
            summary = (Path(temp)/"summary.md").read_text()
        self.assertIn("star-meta-aaaaaaaa", summary)
        self.assertIn("star-desktop-renderer-aaaaaaaa.json", summary)
        self.assertEqual(uploaded["content"], manifest)
        self.assertEqual(calls[0][2], "star-meta-aaaaaaaa")
        self.assertEqual(calls[1][2], "star-meta-aaaaaaaa")

    def test_release_tags_are_separate(self):
        text = WORKFLOW.read_text(encoding="utf-8")
        self.assertIn("Docker/scripts/prepare-releases.sh", text)
        self.assertIn("star-build-", text)
        self.assertIn("star-meta-", (
            ROOT / "Docker/scripts/prepare-releases.sh"
        ).read_text(encoding="utf-8"))
        self.assertIn("github.event_name != 'pull_request'", text)

    def test_manifest_builder_has_explicit_provenance(self):
        self.assertTrue(PUBLISHER.is_file(), "Publisher script missing")
        spec = importlib.util.spec_from_file_location("star_publisher", PUBLISHER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        sha = "a" * 40
        digest = "sha256:" + "b" * 64
        manifest = module.make_manifest("web-assets", sha, "ls-matheus", digest)
        self.assertEqual(manifest["component"], "web-assets")
        self.assertEqual(manifest["source_commit"], sha)
        self.assertEqual(manifest["digest"], digest)
        self.assertEqual(
            manifest["immutable_image"],
            "ghcr.io/ls-matheus/star-web-assets@" + digest,
        )

    def test_manifest_rejects_untrusted_names_and_digests(self):
        self.assertTrue(PUBLISHER.is_file(), "Publisher script missing")
        spec = importlib.util.spec_from_file_location("star_publisher", PUBLISHER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        for component, sha, owner, digest in (
            ("../../other", "a" * 40, "ls-matheus", "sha256:" + "b" * 64),
            ("server", "not-a-sha", "ls-matheus", "sha256:" + "b" * 64),
            ("web-assets", "a" * 40, "other/path", "sha256:" + "b" * 64),
            ("web-assets", "a" * 40, "ls-matheus", "sha256:invalid"),
        ):
            with self.subTest(component=component, sha=sha):
                with self.assertRaises(ValueError):
                    module.make_manifest(component, sha, owner, digest)


if __name__ == "__main__":
    unittest.main()
