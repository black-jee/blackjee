# BLACK-JEE Storage security plan — 2026-10-24

## Status

**Design only. No bucket, policy, object, or production setting was created or changed.** The live catalog currently has no Storage buckets and no Storage RLS policies. The source archive contains 21 image assets; none are migrated by this plan.

## Asset classes and proposed boundaries

### 1. Published PYQ images

- Candidate bucket: `pyq-public`, public-read only if every object placed there is approved for public publication.
- Object paths should be deterministic and relative, for example `<question-id>/statement.<ext>` and `<question-id>/option-<n>.<ext>`; the actual mapping must be derived from the source manifest and reviewed before import.
- Uploads, replacement, and deletion must be restricted to trusted admin/server workflows. Public bucket visibility is not an authorization mechanism for writes.
- Do not upload draft, rejected, answer-key, worked-solution, or unreleased challenge assets into this bucket.
- Keep the current database path validation and add an import-time check that every referenced object exists and its MIME type/size is permitted.

### 2. Daily-challenge images and unreleased assets

- Candidate bucket: `challenge-private`, **private**.
- Do not rely on hiding `statement_image_path`, obscure paths, or an authenticated-only Storage policy as the release gate. Any authenticated user could otherwise try to fetch another challenge's object if object access is granted too broadly.
- The browser must not receive a service-role key or unrestricted Storage credentials.
- Preferred serving flow: a trusted server-side handler verifies the current user and the corresponding active `private.daily_challenge_sessions` row, checks the challenge window/release rules, then issues a short-lived signed URL for only the authorized object. The server must not trust a client-supplied object path without validating it against the challenge row.
- If the current RPC contract returns only a relative path, add signed-URL resolution in the server workflow before using private images. Do not make the bucket public to avoid implementing that gate.
- Apply the same private boundary to option images and any future challenge-specific diagrams.

## Import and validation gates

1. Build a manifest mapping each source image to its intended question/challenge, role (statement/option), MIME type, byte size, and intended visibility. Do not include question/answer/solution text in the manifest unless needed; identifiers and file metadata are sufficient.
2. Reject path traversal, absolute paths, unexpected characters, unsupported extensions/MIME types, oversized files, and duplicate destination paths.
3. Upload only to a disposable/test bucket first; verify object listing, read access, signed URL expiry, and denial cases before production changes.
4. Check every database image reference against the uploaded-object manifest; fail closed for missing objects.
5. Verify no private challenge asset is readable anonymously, by an authenticated user without an active matching session, or after the permitted access window.
6. Test admin upload/replace/delete authorization and ensure object metadata does not reveal answer keys or worked solutions.
7. Document rollback: remove only newly uploaded test objects/buckets after explicit review; do not delete existing production objects as part of a dry run.

## Required negative tests

- Anonymous user cannot read any private challenge object.
- Authenticated user without an active session cannot read another challenge's private object.
- User A cannot resolve a signed URL for User B's session or a different challenge.
- Expired signed URLs stop working within the documented TTL.
- A draft/unapproved PYQ image is not reachable through the public bucket.
- Non-admin users cannot upload, overwrite, or delete assets.
- A client-supplied path cannot escape the authorized question/challenge prefix.

## Implementation decision gate

Before creating any bucket or policy, review the proposed policy SQL and server handler against the current frontend/RPC contract. Prefer separate buckets and clearly separate code paths over one bucket with complex per-object rules. Run the tests in a disposable environment first. Production Storage changes require separate explicit approval; this document is not authorization to apply them.

## Current blockers

- No Storage bucket/policy exists in the live project.
- Source image mapping and visual verification are incomplete.
- Real Supabase-issued user-token tests and signed-URL expiry/authorization tests have not run.
- Do not mark image migration complete until these gates pass.
