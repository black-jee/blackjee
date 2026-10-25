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
    if not value or "\x00" in value or "\\" in value or ":" in value:
        return False
    path = PurePosixPath(value)
    return bool(path.parts) and not path.is_absolute() and all(
        part not in {"", ".", ".."} for part in path.parts
    )


def sha256(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip_file", type=Path, help="Path to BLACK-JEE-main.zip")
    parser.add_argument("--repo-root", type=Path, default=Path.cwd(), help="New repository root")
    parser.add_argument("--dry-run", action="store_true", help="Validate and report without copying")
    parser.add_argument(
        "--write-public-assets",
        action="store_true",
        help="Explicitly allow copying assets into public/ (makes them publicly accessible)",
    )
    parser.add_argument("--report", type=Path, default=Path("docs/ASSET_IMPORT_REPORT.json"), help="Report path relative to repo root")
    args = parser.parse_args()

    if not args.dry_run and not args.write_public_assets:
        parser.error("Refusing to write question assets into public/ without --write-public-assets; use --dry-run to validate only.")
    if args.report.is_absolute() or not safe_archive_path(args.report.as_posix()):
        parser.error("--report must be a safe relative path inside --repo-root.")

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
                if not isinstance(question, dict):
                    raise ValueError("Each manifest entry must be a JSON object.")
                assets = question.get("assets", []) or []
                if not isinstance(assets, list):
                    raise ValueError("Each question assets field must be a JSON array.")
                for asset in assets:
                    if not isinstance(asset, dict):
                        raise ValueError("Each asset reference must be a JSON object.")
                    filename = asset.get("filename")
                    if (
                        not isinstance(filename, str)
                        or not safe_archive_path(filename)
                        or "/" in filename
                    ):
                        raise ValueError("Manifest contains an invalid asset filename.")
                    referenced.add(filename)

            image_dir = package_prefix + "images/"
            archive_images = sorted(
                name for name in names
                if name.startswith(image_dir)
                and name != image_dir
                and Path(name).suffix.lower() in SUPPORTED
                and safe_archive_path(name)
            )
            archive_by_name: dict[str, str] = {}
            for archive_name in archive_images:
                filename = Path(archive_name).name
                if filename in archive_by_name:
                    raise ValueError(f"Duplicate image basename is ambiguous in the archive: {filename}")
                archive_by_name[filename] = archive_name

            for filename in sorted(referenced):
                if filename not in archive_by_name:
                    missing.append(filename)
            if missing:
                raise ValueError(
                    "Referenced image files are missing; refusing partial import: "
                    + ", ".join(missing)
                )

            repo_root = args.repo_root.resolve()
            public_root = (repo_root / "public").resolve()
            if not public_root.is_relative_to(repo_root):
                raise ValueError("Public asset destination resolves outside --repo-root.")

            for filename, archive_name in archive_by_name.items():
                if archive.getinfo(archive_name).file_size > MAX_FILE_BYTES:
                    raise ValueError(f"Image exceeds {MAX_FILE_BYTES} bytes: {filename}")
                content = archive.read(archive_name)
                if len(content) > MAX_FILE_BYTES:
                    raise ValueError(f"Image exceeds {MAX_FILE_BYTES} bytes: {filename}")
                relative = PACKAGE + "images/" + filename
                destination = repo_root / "public" / relative
                if not destination.resolve().is_relative_to(public_root):
                    raise ValueError(f"Asset destination resolves outside public/: {filename}")
                if not args.dry_run:
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    if not destination.resolve().is_relative_to(public_root):
                        raise ValueError(f"Asset destination resolves outside public/: {filename}")
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

    report_path = args.repo_root.resolve() / args.report
    if not report_path.resolve().is_relative_to(args.repo_root.resolve()):
        print("Asset import failed: report destination resolves outside --repo-root.", file=sys.stderr)
        return 2
    if not args.dry_run:
        report_path.parent.mkdir(parents=True, exist_ok=True)
        if not report_path.resolve().is_relative_to(args.repo_root.resolve()):
            print("Asset import failed: report destination resolves outside --repo-root.", file=sys.stderr)
            return 2
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
