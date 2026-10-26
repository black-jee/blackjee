# Asset inventory audit — 2026-10-26

**Source:** `blackjee-foundation.zip` → `blackjee-foundation/public/assets/questions/jee-main-2026-apr-4-shift-1/`  
**Scope:** file integrity and manifest-reference audit only; not visual/source-PDF verification.

## Summary

- 19 image files found; all 19 are referenced by the 75-slot `manifest.json` and every manifest image reference resolves to a file.
- All 19 files decode and verify as PNG; no missing references, unreferenced images, or duplicate SHA-256 hashes were found.
- Total image bytes: 941,582 (about 0.90 MiB); file sizes range from 5,976 to 148,860 bytes.
- Image dimensions range from 81×47 to 780×504 pixels.
- **All 19 manifest entries remain `CROP_PRESENT_UNVERIFIED`; `visual_details_verified` is false.** This audit does not prove fidelity to the official exam PDF or correctness of the depicted question/option. Keep content unpublished until that review is complete.
- Live Supabase has 0 Storage buckets, 0 objects, and 0 Storage policies. Five target PYQ rows have no statement-image, option-image, or `asset_paths` references. No asset upload or Storage configuration was performed.

## Referenced PNG files

- `BJ-JM-20260404-S1-CHE-062-matching-1.png`
- `BJ-JM-20260404-S1-CHE-064-option_a-2.png`
- `BJ-JM-20260404-S1-CHE-064-option_b-3.png`
- `BJ-JM-20260404-S1-CHE-064-option_c-4.png`
- `BJ-JM-20260404-S1-CHE-064-option_d-5.png`
- `BJ-JM-20260404-S1-CHE-064-reaction-1.png`
- `BJ-JM-20260404-S1-CHE-065-matching-1.png`
- `BJ-JM-20260404-S1-CHE-066-reaction-1.png`
- `BJ-JM-20260404-S1-CHE-067-reaction-1.png`
- `BJ-JM-20260404-S1-CHE-068-reaction-1.png`
- `BJ-JM-20260404-S1-CHE-069-matching-1.png`
- `BJ-JM-20260404-S1-CHE-070-reaction-1.png`
- `BJ-JM-20260404-S1-CHE-072-reaction-1.png`
- `BJ-JM-20260404-S1-PHY-032-diagram-1.png`
- `BJ-JM-20260404-S1-PHY-038-diagram-1.png`
- `BJ-JM-20260404-S1-PHY-039-diagram-1.png`
- `BJ-JM-20260404-S1-PHY-042-diagram-1.png`
- `BJ-JM-20260404-S1-PHY-043-diagram-1.png`
- `BJ-JM-20260404-S1-PHY-045-diagram-1.png`

## Security disposition

1. Keep the assets as source-archive evidence until the official PDF or another authoritative source is available for visual comparison.
2. Do not publish or upload them merely because the files decode correctly or the manifest references them.
3. When an isolated Storage environment exists, test approved-published image reads, draft/unreferenced image denial, source-PDF denial, student write denial, admin upload, path traversal, MIME/size restrictions, and cross-bucket isolation.
4. Re-run the hash/manifest audit before import and verify every uploaded object's hash and path against the reviewed manifest.
