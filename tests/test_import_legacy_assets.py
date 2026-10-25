from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "import_legacy_assets.py"
PACKAGE = "BLACK-JEE-main/assets/questions/jee-main-2026-apr-4-shift-1/"


class ImportLegacyAssetsTests(unittest.TestCase):
    def make_archive(
        self,
        root: Path,
        *,
        filename: str = "diagram.png",
        image_paths: tuple[str, ...] = ("diagram.png",),
    ) -> Path:
        archive_path = root / "source.zip"
        manifest = [{"id": "sample-question", "assets": [{"filename": filename}]}]
        with zipfile.ZipFile(archive_path, "w") as archive:
            archive.writestr(PACKAGE + "manifest.json", json.dumps(manifest))
            for image_path in image_paths:
                archive.writestr(PACKAGE + "images/" + image_path, b"test-image-bytes")
        return archive_path

    def run_import(
        self, archive_path: Path, repo_root: Path, *flags: str
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                str(archive_path),
                "--repo-root",
                str(repo_root),
                *flags,
            ],
            capture_output=True,
            text=True,
            check=False,
        )

    def test_requires_explicit_opt_in_before_writing_public_assets(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = self.make_archive(root)
            repo = root / "repo"
            result = self.run_import(archive, repo)

            self.assertEqual(result.returncode, 2)
            self.assertIn("--write-public-assets", result.stderr)
            self.assertFalse((repo / "public").exists())

    def test_dry_run_validates_without_copying_or_writing_report(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = self.make_archive(root)
            repo = root / "repo"
            result = self.run_import(archive, repo, "--dry-run")

            self.assertEqual(result.returncode, 0, result.stderr)
            summary = json.loads(result.stdout)
            self.assertTrue(summary["dry_run"])
            self.assertEqual(summary["copied_count"], 1)
            self.assertFalse((repo / "public").exists())
            self.assertFalse((repo / "docs" / "ASSET_IMPORT_REPORT.json").exists())

    def test_rejects_ambiguous_duplicate_image_basenames(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = self.make_archive(
                root,
                image_paths=("left/diagram.png", "right/diagram.png"),
            )
            result = self.run_import(archive, root / "repo", "--dry-run")

            self.assertEqual(result.returncode, 2)
            self.assertIn("Duplicate image basename", result.stderr)

    def test_missing_referenced_image_aborts_before_writing_any_assets(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = self.make_archive(root, filename="missing.png", image_paths=())
            repo = root / "repo"
            result = self.run_import(
                archive, repo, "--write-public-assets"
            )

            self.assertEqual(result.returncode, 2)
            self.assertIn("refusing partial import", result.stderr.lower())
            self.assertFalse((repo / "public").exists())
            self.assertFalse((repo / "docs" / "ASSET_IMPORT_REPORT.json").exists())

    def test_rejects_windows_style_manifest_asset_paths(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = self.make_archive(root, filename=r"..\\diagram.png")
            result = self.run_import(archive, root / "repo", "--dry-run")

            self.assertEqual(result.returncode, 2)
            self.assertIn("invalid asset filename", result.stderr)

    def test_rejects_report_path_traversal(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = self.make_archive(root)
            repo = root / "repo"
            result = self.run_import(
                archive, repo, "--dry-run", "--report", "../outside.json"
            )

            self.assertEqual(result.returncode, 2)
            self.assertIn("safe relative path", result.stderr)
            self.assertFalse((root / "outside.json").exists())

    def test_rejects_invalid_manifest_asset_paths(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            archive = self.make_archive(root, filename="../diagram.png")
            result = self.run_import(archive, root / "repo", "--dry-run")

            self.assertEqual(result.returncode, 2)
            self.assertIn("invalid asset filename", result.stderr)


if __name__ == "__main__":
    unittest.main()
