# Migration plan

## Guardrails

- Original source: uploaded ZIP and original public GitHub Pages app.
- Target code: `https://github.com/black-jee/blackjee`.
- Target backend: Supabase project `phdssyexhfyxsmhmmcgb`.
- No dependency on or writes to the old Supabase project.
- No production website cutover without explicit owner approval.

## Stage 0 — Audit and baseline (in progress)

- [x] Confirm ZIP readable; enumerate archive.
- [x] Identify 17 HTML entrypoints, source SQL, Edge Functions, assets, manifests, audit scripts and workflows.
- [x] Inspect target project status, tables, migration history, functions and advisors.
- [ ] Finish page-by-page behavior and RPC dependency map.
- [ ] Reconcile original schema against target baseline.
- [ ] Confirm the original website's live behavior using a browser-capable check.

## Stage 1 — Foundation (in progress)

- [ ] Next.js App Router, React, strict TypeScript, Tailwind, shared layout and design tokens.
- [ ] Zod schemas, Supabase SSR/browser clients and environment templates.
- [ ] KaTeX question-rendering primitive with safe text/image fallback.
- [ ] Vitest and Playwright harnesses.
- [ ] GitHub Actions checks for formatting/lint, type-check, tests and production build.

## Stage 2 — Database compatibility and security

- [ ] Export target baseline DDL/policies/grants/functions to repository migrations.
- [ ] Create explicit source-to-target mapping for daily challenge, attempts, answer keys and PYQs.
- [ ] Review all security-definer RPCs and grants; fix confirmed over-permission without breaking required flows.
- [ ] Add RLS and negative permission tests.
- [ ] Deploy and verify Edge Functions only after their secrets and behavior are reviewed.
- [ ] Add additive migrations with migration files committed before apply.

## Stage 3 — Student features

- [ ] Auth/session and profile.
- [ ] Dashboard and challenge schedule.
- [ ] Challenge start/attempt/submit/timer/photo.
- [ ] Results archive and timed solution release.
- [ ] PYQ browse, search, chapter navigation and grading.
- [ ] Chapter practice and mock tests.

## Stage 4 — Admin/content workflows

- [ ] Admin role and dashboard.
- [ ] Daily challenge authoring/scheduling/publishing.
- [ ] Submission review, CSV export and safe cleanup.
- [ ] PYQ draft/import/review/publish.
- [ ] Shift workbench, diagram review, crop studio and asset QA.
- [ ] Audit log and storage cleanup.

## Stage 5 — Content and QA

- [ ] Import content with deterministic source IDs and asset-path validation.
- [ ] Keep unresolved questions as drafts; do not infer answer keys or fabricate diagrams.
- [ ] Unit/integration tests for core logic.
- [ ] Playwright workflows at desktop and mobile viewport.
- [ ] Accessibility, performance, error and empty-state review.
- [ ] Security/performance advisors and negative access tests.

## Stage 6 — Staging and launch

- [ ] Configure a compatible Next.js host and separate staging/prod environment variables.
- [ ] Run smoke tests against staging Supabase.
- [ ] Configure monitoring, structured logs, backup/restore and rollback.
- [ ] Deliver launch checklist and wait for owner approval before production cutover.

## Data recovery limitations

The ZIP contains source code and a staging question package, not an export of old production database rows, auth users, upload objects, or secrets. Those items cannot be assumed recovered. The April 4 Shift 1 dataset has documented unresolved content and must not be published until reconciled to an authoritative paper.
