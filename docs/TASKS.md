## Latest checkpoint — 2026-10-26 (CI #711 green; release gate regression retained)

- **Verified test commit:** `0219fd7b293967d6a7d54d04fdf718df8b5e168f`; CI [#708 / 40246416154](https://github.com/black-jee/blackjee/actions/runs/40246416154) passed both `quality` and `reconstruction-replay`.
- **New release-gate regression:** disposable replay proves the daily-challenge result omits `correct_answer` and `solution` before release, then exposes the expected synthetic values after release. The authorization suite completed successfully.
- **Quality evidence:** continuity validation, static security contracts, dependency audit, lint, typecheck, unit tests, Playwright E2E, formatting, and production build passed on run #708.
- **Migration status:** 20 live applied versions, 24 repository SQL files, 18 exact filename/version matches, two unresolved applied bodies, and six repository-only SQL files.
- **Remaining source recovery:** `20261024081337_numeric_answers_and_admin_review` (archive has only similar-purpose version `20261024081110`) and `20261024112132_require_pyq_source_page_before_publish`. Exact-version global commit searches returned no source hit; do not substitute the near-match.
- **Security gap:** replay uses synthetic fixtures and simulated PostgreSQL JWT claims, not signed Supabase Auth tokens. Cross-user mock-test resume/submit/result and daily-challenge session-submission denials are covered; signed-token/authenticated-client integration and broader release-boundary runtime tests remain unverified.
- **External check:** Vercel reports a platform build-rate-limit/upgrade failure. Do not create paid resources; this is separate from the green repository CI jobs.
- **Safety:** no production schema/data/grant/ledger mutation or JEE content import. PR #2 remains draft and unmerged.

# BLACK-JEE task ledger

**Last reconciled:** 2026-10-26. One authoritative entry per task; update this file as evidence changes.

Status vocabulary: `DISCOVERED`, `PLANNED`, `IN_PROGRESS`, `BLOCKED`, `IMPLEMENTED`, `TESTED`, `DEPLOYED`, `PRODUCTION_VERIFIED`.

## P0 — release safety and security

### BJ-SEC-001 — Preserve PYQ publish gate

- **Status:** TESTED (database definition and grants inspected; authenticated browser publishing not tested)
- **Acceptance:** publish requires source document + page, non-empty statement, private answer key, worked solution, and valid option label for single-correct questions; anonymous execution denied.
- **Evidence:** live Supabase function definition includes source-page and private-key/solution checks; anon execute=false, authenticated execute=true. Five PYQs remain unpublished.
- **Next:** run a safe negative/positive integration test with a dedicated admin test account and disposable draft; never publish real content during the test.

### BJ-SEC-002 — Verify SECURITY DEFINER RPC boundary

- **Status:** IN_PROGRESS
- **Acceptance:** all exposed privileged RPCs have a pinned search path, no anonymous execution, server-side authorization, and cross-user/release-boundary tests for student workflows.
- **Evidence:** read-only catalog review is recorded in [`docs/SECURITY_DEFINER_REVIEW_2026-10-24.md`](./SECURITY_DEFINER_REVIEW_2026-10-24.md). Eleven public SECURITY DEFINER functions are owned by `postgres`, pin an empty `search_path`, and have no anonymous execute grant. The three admin RPCs check server-managed `app_metadata.role = admin`; direct SELECT/INSERT checks for the five private answer/session tables deny `anon`, `authenticated`, and `service_role`. Existing SQL catalog contract assertions passed previously, but authenticated cross-user and release-boundary runtime tests remain unverified.
- **Next:** add isolated tests proving student A cannot read, resume, submit, or retrieve results for student B; verify anonymous denial, ordinary-user admin denial, and daily-solution/PYQ release boundaries. Do not mutate production data or publish test content.

### BJ-DB-001 — Recover and reconcile the two remaining missing applied migration bodies

- **Status:** IN_PROGRESS
- **Acceptance:** clean isolated database replay reproduces target schema, constraints, grants, RLS, functions, and indexes; diff against live target reviewed.
- **Risk:** two applied migration bodies remain missing after five exact-version bodies were restored from the Library archive; live history has 20 versions and the repository now has 24 SQL files (18 exact matches). Repository migration directory has version drift: live `20261024112132_require_pyq_source_page_before_publish` is missing while `20261024112500` and `20261024120000` files are not recorded as applied.
- **Evidence:** read-only comparison documented in [`docs/MIGRATION_RECONCILIATION.md`](./MIGRATION_RECONCILIATION.md); public columns, constraints/FKs, RLS, public policies, table grants, partial routine definitions/ACLs, private tables, triggers and storage bucket/policy counts inspected. No app triggers, private-schema policies or storage buckets were found. Five bodies have been restored byte-for-byte from `blackjee-foundation.zip`; the remaining unresolved versions are `20261024081337` and `20261024112132`. The archive's `20261024081110` file is not treated as the `20261024081337` original. Recovery checks and exact blob IDs are recorded in [`docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`](./MIGRATION_RECOVERY_SEARCH_2026-10-24.md). Latest CI run [40101661444](https://github.com/black-jee/blackjee/actions/runs/40101661444) and GitHub Pages run [40101661202](https://github.com/black-jee/blackjee/actions/runs/40101661202) both passed on HEAD `ffc1437b1381bb000c6a1417210e9891182509a0`. This confirms configured CI and Pages workflow status only; production deployment linkage and database replay remain unverified.
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

## Continuation update — 2026-10-26

### Source recovery checkpoint

- **Recovery result:** all five ZIP archives currently visible in the Library were inspected directly. The foundation archive contains only the different-version `20261024081110_numeric_answers_and_admin_review.sql`; the four `BLACK-JEE-main*.zip` archives are byte-identical and contain neither unresolved migration. No original body was recovered.
- **Unresolved originals:** `20261024081337_numeric_answers_and_admin_review` and `20261024112132_require_pyq_source_page_before_publish`.
- **Inventory:** 20 live applied versions; 24 repository SQL files; 18 exact version/name matches; two unresolved applied bodies; six repository-only SQL files.
- **Safety:** no production schema/data/grant/ledger mutation, no migration repair/reset, no paid infrastructure, no JEE content invention, and no PR merge.

### Current CI follow-up

- CI [run #686 / 40244658935](https://github.com/black-jee/blackjee/actions/runs/40244658935) ran on commit `7cadd5bf14f3e2967644ca68d0abe60949c74967`. `reconstruction-replay` passed; `quality` failed only at Prettier. Job logs name `docs/MIGRATION_RECONCILIATION.md`, `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`, and `docs/SESSION_HANDOVER.md` as the three formatting failures. Lint, typecheck, unit tests, Playwright E2E, dependency audit, and build passed.
- A formatting-only correction was committed in these three documents. Follow-up [run #692 / 40245119398](https://github.com/black-jee/blackjee/actions/runs/40245119398) failed at the continuity validator because the continuation notes duplicated the permanent IDs `BJ-DB-001` and `BJ-DOC-001`; those headings have since been changed to descriptive headings without task IDs. The reconstruction assertions completed successfully before the overall job was cancelled due to the quality failure. Current HEAD still has no matching CI run and is not yet verified green. Do not report the current branch as green until a matching run passes.

### Latest continuation checkpoint — 2026-10-26 (CI #711 green)

- **Verified source/test commit:** `4d0f8d879a1f5c25b332cfae474218e75aee8479` is the branch HEAD at the start of this checkpoint. Its change is documentation-only spacing cleanup in `docs/TASKS.md`.
- **CI:** [run #711 / 40246608312](https://github.com/black-jee/blackjee/actions/runs/40246608312) completed successfully on the current branch source: `quality` and `reconstruction-replay` both have conclusion `success`. Quality passed dependency audit, lint, typecheck, unit tests, Playwright E2E, formatting, and build. Replay passed schema/constraint/index, RLS, RPC, ACL, authoring integrity, mock-test validation, and RPC denial checks, including the daily-challenge answer/solution release-boundary regression.
- **Security precision:** CI's replay uses disposable PostgreSQL, synthetic identities, and simulated JWT claim settings. It is not signed-token or real Supabase Auth integration. Real authenticated-client integration and broader release-boundary runtime tests remain open.
- **Migration blockers unchanged:** 20 live applied versions, 24 repository SQL files, 18 exact filename/version matches, two unresolved applied bodies, and six repository-only SQL files. Exact originals remain `20261024081337_numeric_answers_and_admin_review` and `20261024112132_require_pyq_source_page_before_publish`. Do not substitute `20261024081110` for the first.
- **External deployment:** Vercel's build-rate-limit/upgrade blocker is separate from green repository CI. No paid infrastructure is authorized.
- **Next:** continue free, evidence-backed search for the exact historical migration bodies; meanwhile design real signed-token/authenticated-client tests only with isolated test credentials and fixtures. Do not mutate production Supabase, invent historical SQL or JEE content, or merge PR #2.
