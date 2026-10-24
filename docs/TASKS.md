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
- **Risk:** six original migration bodies absent from Git; live history has 20 versions. Repository migration directory has version drift: live `20261024112132_require_pyq_source_page_before_publish` is missing while `20261024112500` and `20261024120000` files are not recorded as applied.
- **Evidence:** read-only comparison documented in [`docs/MIGRATION_RECONCILIATION.md`](./MIGRATION_RECONCILIATION.md); public columns, constraints/FKs, RLS, public policies, table grants, partial routine definitions/ACLs, private tables, triggers and storage bucket/policy counts inspected. No app triggers, private-schema policies or storage buckets were found. The reference repo has a different migration sequence and is not authoritative for the six missing versioned bodies. CI run [40098020175](https://github.com/black-jee/blackjee/actions/runs/40098020175) passed all configured checks on commit `b4d23d1b6a5d5a3a629e2f32485ce4c233abe824`; subsequent documentation-only commits triggered fresh CI runs that must be checked before claiming the newest HEAD is green.
- **Next:** continue free Git-history/artifact recovery and investigate no-cost isolated replay options (for example, a temporary PostgreSQL service in GitHub Actions if a reviewed replayable chain can be assembled). Owner has stated they cannot afford a paid branch; do not create any billable Supabase branch/project. If original bodies cannot be recovered, label reconstructed equivalents explicitly and compare schema/security behavior in isolation. Never reset or alter the target project.

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

- **Status:** TESTED
- **Acceptance:** context, status, feature inventory, architecture, database, security, decisions, tasks, test plan, releases, SEO/growth, changelog, continuity startup prompt, session handover, and verification log are present and reconciled; CI checks required files and handover/task consistency.
- **Evidence:** added `docs/CONTINUITY_SYSTEM_PROMPT.md`, `docs/SESSION_HANDOVER.md`, `docs/VERIFICATION_LOG.md`, `scripts/check-continuity.mjs`, and a CI validation step. Direct Supabase migration listing returned 20 applied versions. CI run `40091830452` passed all configured gates, including the continuity validator, Prettier, and production build; it also committed the formatter corrections as `b6bb46d81ce81b803296aa6c9421ca611b03f8b3`.
- **Next:** maintain these records after each meaningful change; resume BJ-DB-001 and reconstruct the missing migration baseline only in isolated staging.
