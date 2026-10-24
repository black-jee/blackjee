# Security plan

## Threat model

Protect student identity and history, unpublished questions, answer keys, challenge sessions, solution photos, admin publishing controls, and destructive content-management operations. Assume browser inputs, local clocks, user metadata, URLs and client-side role flags are untrusted.

## Required controls

- Supabase Auth sessions handled with supported Next.js SSR cookie integration.
- Admin authorization enforced in server actions/route handlers and in privileged database functions. Read role only from server-managed `app_metadata` or a protected role table.
- RLS on every exposed-schema table; explicit grants and policies must be reviewed together.
- Student ownership predicate for every user-specific record; UPDATE policies need both `USING` and `WITH CHECK`.
- Answer keys/solutions stored separately from public question payloads and returned only after release/attempt rules pass.
- Server/database-enforced attempt uniqueness, challenge window, elapsed-time bounds, and answer submission.
- Private Storage buckets, file type/size checks, randomized object paths, ownership-aware policies and short-lived signed URLs.
- Zod validation for route params, request bodies, imports and uploads; safe error responses.
- Rate limiting where abuse risk justifies it; audit records for sensitive admin actions.
- Dependency lockfile, pinned CI runtime, secret scanning and no credentials in Git.
- Explicit session, password reset, account deletion, backup/restore and secret rotation procedures.

## Baseline risks observed (2026-10-24)

Supabase security advisors reported:
1. `public.get_current_daily_challenge()` is `SECURITY DEFINER` and callable by `anon` and `authenticated`.
2. Five `SECURITY DEFINER` RPCs are executable by authenticated users; inspect each function body and intended public contract before changing grants.
3. Four private tables have RLS enabled with no policies. This is not automatically a vulnerability if browser roles have no direct privileges, but grants and schema exposure must be verified.
4. The new project has no Edge Functions deployed, while the source relies on `admin-cleanup` and `released-solution` workflows.

These findings are tracked, not silently “fixed” by blanket revocation, because student challenge start/submission and grading legitimately require narrowly controlled server functions.

## Required negative tests

- Anonymous user cannot see unreleased statement/answer/solution or private uploads.
- Student A cannot read, update, delete or grade through Student B's records.
- Student cannot create or modify admin roles or publish content.
- Student cannot bypass one-attempt restrictions by changing client clocks, request bodies or repeating RPCs.
- A direct REST call cannot bypass server authorization.
- Admin endpoints reject missing/expired sessions and non-admin users.
- Upload rejects disallowed type, oversized files, invalid ownership and path traversal.
- Draft PYQs and unreviewed image assets never appear in student queries.
- Destructive cleanup requires admin role, confirmation, and safe association checks.

## Operational note

Do not paste or commit passwords, service-role keys, secret API keys, OAuth client secrets, or database connection strings. Use deployment/provider secret stores and `.env.local` excluded from Git. Leaked-password protection is a dashboard-level action to verify before launch.
