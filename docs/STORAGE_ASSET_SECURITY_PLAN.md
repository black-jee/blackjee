# Storage and asset security plan

**Status:** DESIGN ONLY — no bucket or Storage policy has been created.
**Environment:** Production Supabase project `phdssyexhfyxsmhmmcgb` was inspected read-only. A fresh read-only SQL query on 2026-10-26 returned **0 rows in `storage.buckets`, 0 rows in `storage.objects`, and 0 policies in schema `storage`** (the same query found 10 application policies in `public`/`private`). Recheck before provisioning.
**Rule:** Do not use production to test uploads, do not store source PDFs/answer keys in a public bucket, and do not invent or upload unverified JEE assets.

## Asset classes and intended access

| Asset class | Suggested bucket | Anonymous/student read | Upload/update/delete |
|---|---|---|---|
| Published PYQ statement/option images | `pyq-question-assets` (private bucket with row-based SELECT policy) | Only when an exact object path is referenced by an approved, published question | Admin-only; validate content and path |
| Original exam/source PDFs and provenance scans | `pyq-source-documents` (private) | Never | Admin-only; review/audit workflow |
| Worked-solution images, answer-key scans, moderation evidence | `pyq-review-private` (private) | Never | Admin-only; never exposed through public question payloads |

Do not create these buckets automatically from this plan. First confirm the asset format, expected file sizes, and whether a signed-URL delivery endpoint is required. If public question images are served through a private bucket, use short-lived signed URLs or an explicitly reviewed read policy tied to a published question. Never make source documents or review materials public to simplify rendering.

## Object path contract

- Generate object paths server-side. Do not accept arbitrary absolute paths, URLs, bucket names, or path traversal segments from a browser.
- Use stable, opaque IDs and an allowlisted extension; do not put student email, answer text, or secrets in object names.
- Store only bucket-relative object names in `statement_image_path`, option `imagePath`, and `asset_paths`. Normalize to one canonical form and compare exact names when checking whether an asset is referenced.
- Enforce an allowlist of MIME types, maximum byte size, and image dimensions; inspect actual file signatures rather than trusting the filename or client Content-Type.
- Strip EXIF/metadata where practical, reject SVG/HTML and other active content unless a dedicated sanitization pipeline exists, and serve downloads with safe content-type/disposition headers.
- Prevent overwrite by default. If upsert is ever enabled, explicitly test INSERT + SELECT + UPDATE policies together.
- Validate that uploaded objects are referenced by the intended synthetic or real draft before allowing publication. Deleting or replacing an object must not silently break a published question.

## Policy design before implementation

1. Keep every bucket private by default.
2. Admin writes require a valid Supabase Auth identity and a server-managed `app_metadata.role = 'admin'` claim. Never trust `user_metadata` for authorization.
3. A question-image SELECT policy may allow `anon` and `authenticated` to read an object only when its exact object name is referenced by a row in `public.jee_pyq_questions` with both `is_published = true` and `review_status = 'approved'`. The predicate must check `statement_image_path`, option image paths, and `asset_paths` without broadening to all objects in the bucket.
4. Source PDFs, answer keys, worked-solution material, and moderation files have no browser-role SELECT policy. Access them through narrowly scoped server/admin flows.
5. Write policies must constrain bucket ID and the allowed path namespace, validate admin role from `auth.jwt()->'app_metadata'`, and include both `USING` and `WITH CHECK` for UPDATE.
6. Keep service-role/secret keys server-only. Never place them in `NEXT_PUBLIC_*`, client bundles, logs, screenshots, or committed environment files.

## Verification checklist

- [ ] Re-query `storage.buckets` and `storage.objects` before making a change; confirm no unexpected existing bucket/policy.
- [ ] Review and approve bucket names, public/private choice, MIME/size limits, retention and signed-URL expiry.
- [ ] Add policies only through a reviewed migration after the historical migration chain is reconciled; do not patch production ad hoc.
- [ ] In a disposable Storage-enabled Supabase environment, test anonymous read of a draft asset (deny), published referenced question image (allow), unreferenced image (deny), source PDF (deny), student upload/update/delete (deny), admin upload of allowed file (allow), traversal/invalid MIME/oversize upload (deny), and cross-bucket path substitution (deny).
- [ ] Verify answer-key and solution objects never appear in public JSON or browser-visible URLs.
- [ ] Record exact test run, project type, and commit SHA; distinguish a PostgreSQL-only simulation from real Supabase Storage/Auth behavior.

## Current disposition

No bucket or policy was created, and no assets were uploaded. Existing question records may contain paths, but a path string is not evidence that the referenced object exists or is safely readable. Asset import remains blocked on authoritative source files, integrity checks, and an approved bucket/policy implementation.
