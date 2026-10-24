# BLACK-JEE task ledger

**Last reconciled:** 2026-10-24. One authoritative entry per task; update this file as evidence changes.

Status vocabulary: `DISCOVERED`, `PLANNED`, `IN_PROGRESS`, `BLOCKED`, `IMPLEMENTED`, `TESTED`, `DEPLOYED`, `PRODUCTION_VERIFIED`.

## P0 — release safety and security

### BJ-SEC-001 — Preserve PYQ publish gate
- **Status:** TESTED (database definition and grants inspected; authenticated browser publishing not tested)
- **Acceptance:** publish requires source document + page, non-empty statement, private answer key, worked solution, and valid option label for single-correct questions; anonymous execution denied.
- **Evidence:** live Supabase function definition includes source-page and private-key/solution checks; anon execute=false, authenticated execute=true. Five PYQs remain unpublished.
- **Next:** run a safe negative/positive integration test with a dedicated admin test account and disposable draft; never publish real content during the test.

### BJ-DB-001 — Reconstruct the six original migration bodies
- **Status:** IN_PROGRESS
- **Acceptance:** clean isolated database replay reproduces target schema, constraints, grants, RLS, functions, and indexes; diff against live target reviewed.
- **Risk:** six original migration bodies absent from Git; 21 versions recorded in Supabase and 15 migration files currently in repository.
- **Next:** export schema metadata/definitions from the target and reconstruct/review baseline; do not reset target project.

## P1 — critical workflows and deployment confidence

### BJ-REL-001 — Verify active Vercel deployment
- **Status:** DISCOVERED
- **Acceptance:** confirm Vercel project/repository linkage, deployed commit, build result, environment variable presence (never print values), and production smoke tests.
- **Evidence:** owner supplied https://blackjee.vercel.app/; linkage and runtime not yet independently verified.
- **Next:** inspect available deployment metadata and perform non-invasive HTTP/browser smoke tests.

### BJ-E2E-001 — Verify authenticated student/admin journeys
- **Status:** IN_PROGRESS
- **Acceptance:** dedicated test accounts prove auth redirects, student ownership isolation, admin denial for ordinary users, safe PYQ review, and key withholding.
- **Evidence:** CI has Playwright smoke tests, but real authenticated student/admin workflows remain unverified.
- **Next:** inspect current test suite and add database-backed tests using isolated fixtures/test accounts.

## P2 — content, storage, and administration

### BJ-CONTENT-001 — Import April 4 Shift 1 questions safely
- **Status:** BLOCKED
- **Acceptance:** all 75 question slots reconciled against authoritative source, source page, statement, options/figures, answer key, worked solution, and independent QA; all records remain drafts until verified.
- **Evidence:** archive manifest has 75 slots (47 marked content_added, 28 needs_review); official source PDF missing; 5 questions currently exist in target as drafts, 0 published.
- **Next:** prepare source-to-target mapping and import validation tooling; do not fabricate missing content or publish.

### BJ-ASSET-001 — Migrate and validate question images
- **Status:** PLANNED
- **Acceptance:** each referenced image resolves to a reviewed asset with dimensions/type checks and correct access rules; unreleased content remains private.
- **Evidence:** source archive includes image files, but target asset migration and visual verification are incomplete.
- **Next:** inventory each source image against manifest IDs and design a safe upload path.

### BJ-ADMIN-001 — Verify PYQ authoring workflow
- **Status:** IMPLEMENTED
- **Acceptance:** draft save, approve-as-draft, publish/unpublish are tested as admin and denied for non-admin; errors are actionable and answer keys never enter public payloads.
- **Evidence:** `app/admin/pyq` and guarded RPCs exist; runtime browser verification remains pending.
- **Next:** complete authorized browser tests.

## P3 — documentation and discoverability

### BJ-DOC-001 — Maintain constitution-required project records
- **Status:** IN_PROGRESS
- **Acceptance:** context, status, feature inventory, architecture, database, security, decisions, tasks, test plan, releases, SEO/growth, and changelog are present and reconciled.
- **Evidence:** missing records were identified at 2026-10-24 session start.
- **Next:** create missing records and reconcile status after each verified milestone.
