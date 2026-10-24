#!/usr/bin/env python3
"""Safely copy question image assets from the supplied BLACK-JEE ZIP into public/."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import sys
import zipfile

PACKAGE = "assets/questions/jee-main-2026-apr-4-shift-1/"
SUPPORTED = {".png", ".jpg", ".jpeg", ".webp", ".gif"}
MAX_FILE_BYTES = 15 * 1024 * 1024


def safe_archive_path(value: str) -> bool:
    path = PurePosixPath(value)
    return not path.is_absolute() and all(part not in {"", ".", ".."} for part in path.parts)


def sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip_file", type=Path, help="Path to BLACK-JEE-main.zip")
    parser.add_argument("--repo-root", type=Path, default=Path.cwd(), help="New repository root")
    parser.add_argument("--dry-run", action="store_true", help="Validate and report without copying")
    parser.add_argument("--report", type=Path, default=Path("docs/ASSET_IMPORT_REPORT.json"), help="Report path relative to repo root")
    args = parser.parse_args()

    if not args.zip_file.is_file():
        parser.error(f"ZIP file not found: {args.zip_file}")

    package_prefix = "BLACK-JEE-main/" + PACKAGE
    manifest_name = package_prefix + "manifest.json"
    copied: list[dict[str, object]] = []
    missing: list[str] = []
    unreferenced: list[str] = []

    try:
        with zipfile.ZipFile(args.zip_file) as archive:
            names = set(archive.namelist())
            if manifest_name not in names:
                raise ValueError(f"Required question asset manifest is missing: {manifest_name}")
            manifest = json.loads(archive.read(manifest_name).decode("utf-8"))
            if not isinstance(manifest, list):
                raise ValueError("Question asset manifest must be a JSON array.")

            referenced: set[str] = set()
            for question in manifest:
                for asset in question.get("assets", []) or []:
                    filename = asset.get("filename")
                    if not isinstance(filename, str) or not safe_archive_path(filename) or "/" in filename:
                        continue
                    referenced.add(filename)

            image_dir = package_prefix + "images/"
            archive_images = sorted(
                name for name in names
                if name.startswith(image_dir)
                and name != image_dir
                and Path(name).suffix.lower() in SUPPORTED
                and safe_archive_path(name)
            )
            archive_by_name = {Path(name).name: name for name in archive_images}

            for filename in sorted(referenced):
                if filename not in archive_by_name:
                    missing.append(filename)

            for filename, archive_name in archive_by_name.items():
                content = archive.read(archive_name)
                if len(content) > MAX_FILE_BYTES:
                    raise ValueError(f"Image exceeds {MAX_FILE_BYTES} bytes: {filename}")
                relative = PACKAGE + "images/" + filename
                destination = args.repo_root / "public" / relative
                if not args.dry_run:
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    destination.write_bytes(content)
                copied.append({
                    "path": relative,
                    "bytes": len(content),
                    "sha256": sha256(content),
                    "referenced_by_manifest": filename in referenced,
                })

            unreferenced = sorted(set(archive_by_name) - referenced)

    except (zipfile.BadZipFile, UnicodeDecodeError, json.JSONDecodeError, ValueError, OSError) as error:
        print(f"Asset import failed: {error}", file=sys.stderr)
        return 2

    report = {
        "source_zip": args.zip_file.name,
        "source_package": PACKAGE,
        "dry_run": args.dry_run,
        "copied_count": len(copied),
        "referenced_count": len(referenced),
        "missing_referenced_assets": missing,
        "unreferenced_assets": unreferenced,
        "assets": copied,
        "warning": "Copying assets does not verify question wording, answer keys, diagram correctness, or publication approval.",
    }

    report_path = args.repo_root / args.report
    if not args.dry_run:
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False) + os.linesep, encoding="utf-8")

    print(json.dumps({
        "dry_run": args.dry_run,
        "copied_count": len(copied),
        "referenced_count": len(referenced),
        "missing_referenced_assets": missing,
        "unreferenced_assets": unreferenced,
        "report_path": str(args.report),
    }, indent=2))
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
