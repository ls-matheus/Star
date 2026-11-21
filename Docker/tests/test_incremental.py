"""CI regression tests: only affected components should rebuild."""
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "star_incremental", ROOT / "Docker/scripts/star-incremental.py")
CI = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CI)


class IncrementalTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sha = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        CI.HEAD = cls.sha
        cls.fingerprints = CI.fingerprint(cls.sha)
        cls.baseline = {
            "schema": 1, "repository": "ls-matheus/Star", "commit": cls.sha,
            "components": {
                k: {
                    "fingerprint": fp, "source_commit": cls.sha,
                    "artifact_release": "star-build-baseline",
                    "metadata_release": "star-meta-baseline",
                    "assets": ["example.apk"] if k == "apk" else
                              (["example.dmg"] if k == "mac" else
                               (["example.exe"] if k == "windows" else [])),
                    "image_ref": (
                        "ghcr.io/ls-matheus/star-" + CI.IMAGE_NAMES[k]
                        + "@sha256:" + "a" * 64 if k in CI.IMAGE_NAMES else ""),
                } for k, fp in cls.fingerprints.items()
            }
        }

    def plan_flags(self, changed=(), target="apps", force="false"):
        fps = dict(self.fingerprints)
        for key in changed:
            fps[key] = "f"*64
        with tempfile.TemporaryDirectory() as temp:
            output = str(Path(temp) / "out")
            env = {
                "GITHUB_OUTPUT": output,
                "GITHUB_EVENT_NAME": "workflow_dispatch" if force == "true" else "push",
                "STAR_TARGET": target,
                "STAR_FORCE_REBUILD": force,
                "STAR_BEFORE": self.sha,
            }
            with patch.object(CI, "find_cache", return_value=(
                    self.baseline, "star-meta-baseline")), \
                 patch.object(CI, "fingerprint", return_value=fps), \
                 patch.dict(os.environ, env), contextlib.redirect_stdout(io.StringIO()):
                CI.plan(None)
            flags = dict(line.split("=", 1) for line in Path(output).read_text().splitlines())
        return {k for k in CI.COMPONENTS if flags["build_"+k] == "true"}

    def test_unchanged(self):
        self.assertEqual(self.plan_flags(), set())

    def test_mobile_only(self):
        self.assertEqual(self.plan_flags(["apk"]), {"apk"})

    def test_builder_change(self):
        self.assertEqual(self.plan_flags(["mobile", "apk"]), {"mobile", "apk"})

    def test_web_change(self):
        affected = {"web", "desktop", "apk", "mac", "windows"}
        self.assertEqual(self.plan_flags(affected), affected)

    def test_server_only(self):
        self.assertEqual(self.plan_flags(["server"]), {"server"})

    def test_manual_force(self):
        self.assertEqual(self.plan_flags(target="apps", force="true"),
                         set(CI.APP_COMPONENTS))
        self.assertEqual(self.plan_flags(target="server", force="true"),
                         {"server"})

    def test_dependency_hash_mapping(self):
        sources = {
            "Star web": "1"*40, "Star mobile": "2"*40, "Star Server": "3"*40,
            "Docker/Dockerfile.mobile": "4"*40,
            "Docker/scripts/build-android.sh": "5"*40,
            ".github/workflows/star-electron-builder.cjs": "6"*40,
        }
        with patch.object(CI, "git_blob", side_effect=lambda _c, p: sources[p]):
            old = CI.fingerprint("COMMIT")
            sources["Docker/scripts/build-android.sh"] = "7"*40
            changed = CI.fingerprint("COMMIT")
            self.assertEqual({k for k in CI.COMPONENTS if old[k] != changed[k]},
                             {"mobile", "apk"})
            sources["Docker/scripts/build-android.sh"] = "5"*40
            sources["Star web"] = "8"*40
            changed = CI.fingerprint("COMMIT")
            self.assertEqual({k for k in CI.COMPONENTS if old[k] != changed[k]},
                             {"web", "desktop", "apk", "mac", "windows"})

    def test_finalize_keeps_old_origins(self):
        notes, uploads = [], []
        env = {"STAR_BASE_TAG": "star-meta-baseline",
               "STAR_SCOPE_APPS": "true", "STAR_SCOPE_SERVER": "true"}
        env.update({"STAR_BUILT_"+key.upper(): "false" for key in CI.COMPONENTS})
        def mockgh(*args, **kwargs):
            self.assertEqual(args[:2], ("release", "edit"))
            notes.append(args)
        with patch.object(CI, "find_cache", return_value=(self.baseline, "star-meta-baseline")), \
             patch.object(CI, "gh", side_effect=mockgh), \
             patch.object(CI, "release_info", side_effect=lambda tag:
                          {"tagName": tag, "assets": [], "body": "## Notes"}), \
             patch.object(CI, "asset_names", return_value=[]), \
             patch.object(CI, "upload_json", side_effect=lambda *a: uploads.append(a)), \
             patch.dict(os.environ, env), contextlib.redirect_stdout(io.StringIO()):
            CI.finalize(None)
        self.assertEqual(len(notes), 2)
        self.assertEqual(len(uploads), 1)
        self.assertEqual(uploads[0][1], CI.CACHE_NAME)
        new = uploads[0][2]["components"]
        self.assertEqual(set(new), set(CI.COMPONENTS))
        for key in CI.COMPONENTS:
            self.assertEqual(new[key]["source_commit"],
                             self.baseline["components"][key]["source_commit"])


if __name__ == "__main__":
    unittest.main()
