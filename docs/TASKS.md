## Latest checkpoint — 2026-10-26 (CI #729 green; Vercel deployment completed)

- **Verified HEAD:** `6e1ab0a7ab8c8cdff5c3f7493957f639b7c5ad3e`; [CI #729 / 40249786034](https://github.com/black-jee/blackjee/actions/runs/40249786034) passed both `quality` and `reconstruction-replay` on this exact commit.
- **Quality evidence:** dependency audit, lint, typecheck, unit tests, Playwright E2E, formatting, and production build passed. Disposable PostgreSQL replay passed reconstructed schema/catalog, RLS, routine/security attributes, execute ACLs, grants, indexes, authoring integrity, and authorization-denial checks.
- **Deployment status:** GitHub's Vercel commit status now reports `success`, “Deployment has completed,” for this HEAD. This is deployment-provider evidence only; an external HTTP smoke test could not be completed from this session because the available web/container fetches could not resolve `blackjee.vercel.app`. Do not infer the app is down or claim runtime health is verified from that tool limitation.
- **Evidence boundary:** simulated PostgreSQL identity claims are not real Supabase-issued JWT/Auth tests. The real-auth plan remains PLANNED and requires an isolated disposable environment with synthetic users.
- **Migration status:** 20 live applied versions, 24 repository SQL files, 18 exact filename/version matches, two applied bodies unresolved, six repository-only SQL files. Missing exact bodies: `20261024081337_numeric_answers_and_admin_review` and `20261024112132_require_pyq_source_page_before_publish`. Five exact bodies were restored from `blackjee-foundation.zip`; the `20261024081110` file is not a substitute for `20261024081337`.
- **Archive recheck:** the four `BLACK-JEE-main*.zip` Library copies have identical SHA-256 hashes and contain only the legacy-generation migration set; none contains either exact missing filename. The foundation archive contains only the near-match `20261024081110` and no exact `20261024112132` body. Details are in `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`.
- **PR #2:** open, draft, unmerged. No production schema/data/grant/migration-ledger changes, paid infrastructure, or fabricated JEE content.
- **Remaining release gates:** signed-token Auth/student/admin tests, successful external live runtime smoke test, six repository-only migration reconciliation, source/image/answer/solution QA, Storage security validation, and production-readiness/rollback review.
- **Dependency note:** one low-severity KaTeX prototype-pollution advisory remains; suggested remediation is breaking. No unreviewed dependency upgrade was made.
- **This checkpoint refresh is documentation-only; verify CI on the new commit before calling it green.**

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

### Latest continuation checkpoint — 2026-10-26 (formatting follow-up after CI #713)

- Current documentation HEAD after formatting-only corrections: `5d6219a734b918e78552f9cb4052316d358043a2`; preceding task-ledger formatting correction: `87436e42dadf1b0e041ffb5f5b3bd5dc63b4a660`.
- CI [#713 / 40246843924](https://github.com/black-jee/blackjee/actions/runs/40246843924) ran against the preceding documentation checkpoint. `reconstruction-replay` passed; `quality` failed only at Prettier. The log specifically identified excess blank lines before the new checkpoint heading in `docs/TASKS.md` and `docs/SESSION_HANDOVER.md`. Those spacing issues have now been corrected in the two commits above. The latest HEAD has no matching successful workflow run yet; do not claim it is green.
- Run #712 / 40246842441 was cancelled; it is not a code failure and does not verify either job.
- No application or SQL changes were made in this formatting follow-up. Migration blockers and security-test limitations remain as recorded above. PR #2 must remain draft/unmerged; production Supabase stays read-only; no paid infrastructure or invented migration/question content.
- Next action: obtain and inspect a workflow run on `5d6219a734b918e78552f9cb4052316d358043a2`. If formatting passes, resume evidence-backed recovery and isolated real-auth test design.

## Latest verification update — 2026-10-26 (CI #731)

- **HEAD at verification:** `961fd61a05460b7efff01503e05efb48ace302ea`; [CI #731 / 40250098420](https://github.com/black-jee/blackjee/actions/runs/40250098420) passed both `quality` and `reconstruction-replay` on that exact commit. Playwright E2E, lint, typecheck, unit tests, dependency audit, Prettier, build, and disposable PostgreSQL reconstruction/security assertions all passed.
- **Vercel:** current HEAD's provider status is rate-limited (`upgradeToPro=build-rate-limit`). This is not a source CI result. No paid upgrade; live runtime/browser smoke test remains unverified.
- **No change to outstanding gates:** exact historical bodies `20261024081337_numeric_answers_and_admin_review` and `20261024112132_require_pyq_source_page_before_publish` remain unrecovered; real Supabase signed-token Auth tests remain unexecuted; six repository-only migrations, Storage security, asset and JEE source/answer/solution QA, and production-readiness/rollback review remain open.
- **Safety:** PR #2 remains draft/unmerged. Production Supabase stays read-only; no fabricated migration SQL or JEE content and no paid infrastructure.

## Autonomous 12-phase execution checklist — 2026-10-26

Status legend: [x] verified complete; [~] in progress or partially verified; [ ] not yet verified; [!] blocked.

1. [~] **CI and repository health** — CI #734 passed on `a19c59e08b129d622e54c03eb52760d1333bcc0e`; both `quality` and `reconstruction-replay` succeeded. Evidence: https://github.com/black-jee/blackjee/actions/runs/40250654516. Vercel status remains a separate rate-limit failure.
2. [~] **GitHub and PR** — PR #2 confirmed open, draft, and unmerged. Refresh documentation/PR evidence after current changes; keep draft.
3. [~] **Migration recovery and inventory** — 20 live versions / 24 repository SQL files / 18 exact matches / two missing historical bodies / six repository-only files are documented. The numeric-answer candidate remains non-deployable and is under isolated CI replay; first attempt failed on duplicate existing constraint, then candidate was adjusted. Verify the new run; exact originals remain unresolved.
4. [~] **Database integrity and reconciliation** — inventory is documented in `docs/MIGRATION_RECONCILIATION.md`; no production writes. Candidate replay has not yet been verified after correction; do not infer migration equivalence.
5. [~] **Real Supabase Auth setup** — added optional signed-token integration harness and environment-variable contract in `docs/REAL_AUTH_INTEGRATION_TEST_PLAN.md`. Execution remains blocked because the connected project inventory exposes only production; do not use it for test writes or create billable infrastructure.
6. [~] **Authorization and RLS** — gated tests now cover anonymous RPC denial, cross-user resume/submit/result, ordinary-student admin denial, unreleased solution withholding, and private-schema access. They are not yet executed against real signed tokens; disposable SQL-claim replay is separate evidence.
7. [~] **Storage and asset security** — design-only plan added at `docs/STORAGE_ASSET_SECURITY_PLAN.md`. Last recorded read-only catalog check found no application buckets/policies; no buckets, policies, or uploads were created. Disposable Storage policy tests and asset validation remain outstanding.
8. [ ] **JEE content quality** — reconcile source manifest, question statements, options, answer keys, worked solutions, citations, and images; keep unverified content unpublished.
9. [ ] **Application workflows** — verify login, PYQ practice, mock tests, results, daily challenges, and admin workflows, distinguishing automated smoke coverage from real authenticated journeys.
10. [!] **Deployment** — Vercel status currently links to a build-rate-limit/upgrade page. Recheck later without paying; live runtime/browser smoke testing remains unverified.
11. [ ] **Performance and reliability** — investigate the unindexed private mock-response question FK and seven unused-index advisories using workload evidence; no speculative production index changes.
12. [ ] **Release readiness** — full regression, security review, rollback plan, evidence reconciliation, and final handover. Do not merge or deploy to production without explicit authorization.

### Execution rules

- Continue autonomously through useful, safe tasks and verify each meaningful repository commit with CI.
- Do not write production Supabase DDL/data/grants or repair/reset its migration ledger.
- Do not invent historical SQL, source citations, answers, or solutions.
- Do not buy infrastructure to bypass rate limits.
- Keep PR #2 open, draft, and unmerged.
- Report a phase complete only when its acceptance evidence exists; record blockers and continue with independent safe tasks.

### Continuation update — 2026-10-26 (CI #737)

- Workflow [#737 / 40252072141](https://github.com/black-jee/blackjee/actions/runs/40252072141) ran on the current documentation tip. `reconstruction-replay` passed; `quality` failed only at Prettier because `docs/TASKS.md` has one extra blank line before the checklist heading and lacks a blank line after `### Execution rules`. Dependency audit, lint, typecheck, unit tests, 22 Playwright tests, and production build passed. These are documentation formatting defects, not application/test failures, but the current tip is not green.
- Phase 1 is now marked partially verified until the formatting-only correction has a matching successful CI run. Vercel remains separately rate-limited; no deployment retry or paid upgrade.

### Task 5–8 follow-up — 2026-10-26

- **Migration inventory:** updated `docs/MIGRATION_RECONCILIATION.md` with the current inventory and explicit candidate provenance/verification boundary. The two missing historical SQL bodies and six repository-only migration files remain unresolved.
- **Candidate replay:** CI [#748 / 40254849919](https://github.com/black-jee/blackjee/actions/runs/40254849919) passed `quality` but failed `reconstruction-replay` when the candidate tried to add a constraint already present in the reconstructed baseline. The candidate was adjusted to drop/recreate the candidate constraint and policy names only in the disposable replay. A matching run must verify this correction before the candidate is considered tested.
- **Real Auth:** added `tests/real-supabase-auth.integration.test.ts`, which uses the official Supabase client to sign in synthetic student A, student B, and admin accounts, then exercises key authorization denials. It is gated on test-only environment variables and skipped when the isolated environment is not configured. The existing connected project list contains only production, so no real-token test has been executed.
- **Storage:** added `docs/STORAGE_ASSET_SECURITY_PLAN.md` with asset classes, private-bucket/policy design, upload validation, and the required denial/allow test matrix. This is a plan only; no production Storage configuration changed.
- **Safety:** production Supabase remains read-only; no paid project/branch was created, no JEE content was fabricated, and PR #2 remains draft/unmerged.
- **Next:** verify the newest CI run and fix reproducible failures; continue only after that with no-cost isolated replay and a disposable Auth/Storage environment.

### Continued work on tasks 5–8 — 2026-10-26

- Rechecked live Supabase migration history read-only: still 20 applied versions. The repository reconciliation remains 24 SQL files, 18 exact filename/version matches, two unresolved historical bodies, and six repository-only files.
- Rechecked Storage catalog read-only: 0 buckets, 0 objects, 0 Storage policies. Aggregate PYQ inventory: 5 rows and zero statement-image, option-image, or asset-path references.
- Re-ran Supabase advisors read-only: five informational private-table RLS/no-policy findings, 11 authenticated-callable SECURITY DEFINER warnings, one unindexed foreign key on private.mock_test_responses.question_id, and seven unused-index notices. No advisor finding was addressed with production DDL; private tables are intended to remain behind guarded RPCs.
- Extended the opt-in real Auth harness to verify that denied cross-user resume/submit calls leave the victim's attempt state unchanged, and that a signed-in admin can create then clean up a synthetic non-live challenge. Added a hard guard that refuses to run against production project ref phdssyexhfyxsmhmmcgb.
- The real Auth suite remains unexecuted: no isolated disposable Supabase Auth project and synthetic fixture IDs are available. CI #748 still records the first candidate-replay failure; later candidate corrections and test changes have no matching workflow result returned by the current workflow lookup.
- **Current repository tip:** see PR #2 for the exact current head SHA. Do not treat any commit after CI #748 as verified until a matching CI run passes.
- No production DDL/data/grant/ledger changes, Storage configuration, asset upload, paid infrastructure, or merge occurred. PR #2 remains draft/unmerged.

## Migration source recovery update — 2026-10-26

- [x] Recover the two missing applied SQL bodies from the authoritative `supabase_migrations.schema_migrations.statements` values.
- [x] Restore them at the exact versioned paths in `supabase/migrations/`; stored SQL statement lengths were 864 and 3341 bytes.
- [x] Remove the candidate-only SQL replay/assertion from active CI so it is no longer treated as historical evidence.
- [ ] Run CI against this commit and confirm the restored migration chain and formatting.
- [ ] Review the six repository-only migrations separately before choosing any canonical migration chain.

Production Supabase was queried read-only only; no production schema/data/grant/ledger change, paid resource, or PR merge occurred.


## Repository-only migration review — 2026-10-26

- [x] Review all six repository-only migrations against the connected production ledger/catalog.
- [x] Identify two redundant admin-review RPC rewrites; one is byte-identical to the recovered applied source-page migration.
- [x] Classify three forward hardening migrations and one index proposal; document test gates and risks in `docs/MIGRATION_REPO_ONLY_REVIEW_2026-10-26.md`.
- [ ] Run the corrected formatting commit's CI to completion.
- [ ] Add/verify focused negative tests for the three forward hardening proposals in a disposable database.
- [ ] Inventory other environment migration ledgers before deleting or renumbering redundant migration files.

No production changes were made.
