# BLACK-JEE project status

**Last updated:** 2026-10-24
**Overall status:** In progress — core application routes and secure database workflows are being built. Not production-ready.

## Environment

- **New GitHub repository:** `black-jee/blackjee`, public, default branch `main`
- **New Supabase:** `phdssyexhfyxsmhmmcgb`, ACTIVE_HEALTHY, PostgreSQL 17.11, Tokyo region
- **Supabase migrations:** last read-only inventory found 20 applied entries and 19 repository SQL migration files (excluding README); 13 exact version/name matches, seven live versions without same-version SQL bodies, and six repository files absent from the live ledger. See the dated reconciliation below; no migration history was repaired
- **Supabase data:** 5 PYQ rows imported as drafts, 5 private answer keys, 0 published questions; 70 source questions remain to be imported
- **Supabase tables:** 9 inspected public/private tables; no student attempts or mock-test attempts
- **Reconstruction replay:** the latest verified completed run for prior HEAD is [40155186509](https://github.com/black-jee/blackjee/actions/runs/40155186509), with both quality and reconstruction-replay jobs passing on `063cf1480d36f8c4c84efebb41438566122dc8c3`. New documentation commits are awaiting their own CI runs. Disposable PostgreSQL replay is not proof of exact historical migration equivalence or real Supabase Auth parity.
- **Supabase Edge Functions:** Original source functions are not deployed. A temporary import endpoint is retired (JWT required, returns HTTP 410)
- **Legacy source ZIP:** Readable; 84 files total, including 75 question slots in the April 4 Shift 1 manifest and 21 image files
- **Live website comparison:** Blocked/incomplete; direct fetch did not return page content

## Work log

- **Verified:** ZIP opens successfully and file inventory enumerated.
- **Verified:** Identified 17 HTML pages, SQL schema/migrations, two legacy Edge Function sources, manifests, question images, Python audits and GitHub workflows.
- **Verified:** Read the source system map, buyer due-diligence notes, import standard, source schema and question-package notes.
- **Verified:** Inspected target Supabase metadata, tables/columns, migration history, function grants and security/performance advisor findings.
- **Implemented:** Next.js App Router / React / TypeScript / Tailwind foundation, Supabase SSR/browser clients, Zod question schema, safe mixed-prose/KaTeX renderer, email/Google sign-in, OAuth callback, password reset/update, profile/history/sign-out, daily challenge route/server actions, published-PYQ browse/filter and authenticated grading, chapter index/practice routes, mock-test runner, and protected admin dashboard/challenge authoring.
- **Implemented and database-verified:** Public schedule RPC now uses invoker privileges; anonymous users can read schedule metadata but not question statements or daily-challenge diagram paths; a session foreign-key index was added.
- **Implemented and database-verified:** Safe optional image-path columns for daily challenge and PYQ questions, with scoped grants. Published PYQ image-path metadata is readable to anonymous visitors; daily challenge diagram paths remain unavailable to anonymous visitors.
- **Implemented and database-verified:** `admin_save_daily_challenge` atomically saves challenge content and private answer keys and checks server-managed `app_metadata.role = admin`. SQL assertions confirmed anonymous execution is denied.
- **Implemented and database-verified:** Mock-test schema/RPCs now support shift/focused test selection, ownership-bound resume/submission, server-side marking, private responses, and the exact 75-question shift validation rule (20 MCQ + 5 numerical per subject). With an empty bank, start is rejected as expected.
- **Tested:** SQL regression assertions for public schedule security, private-table access, admin RPC permissions, mock-test permissions and function ownership checks passed against the target Supabase project.
- **Imported as drafts:** The first 5 Physics questions from the source manifest and their 5 answer keys were imported. They are not published. Their question images are not yet copied into the new application.
- **CI run 40112374432 (commit `f2831f8`, 2026-10-24): PASS.** `npm ci`, continuity validation, ESLint, strict TypeScript, Vitest, Playwright E2E smoke tests, Prettier check, and Next.js production build all completed successfully.
- **Dependency reproducibility:** `package-lock.json` is committed and `npm ci` passed in CI run `40112374432`.
- **Read-only storage/object audit:** No Storage buckets or Storage RLS policies currently exist. No views/materialized views or sequences were found in `public`/`private`, and no non-internal triggers were found in the BLACK-JEE application schemas. Only Supabase-managed Storage triggers appeared. No schema or storage changes were made.
- **Not verified:** Browser behavior, real authenticated student/admin workflows, file upload/storage, full question import, and staging deployment.

## Important findings / blockers

1. **Migration history gap:** The repository lacks seven applied migration bodies (six early baseline bodies and one later publication-gate body) already recorded in the target project. The gap is documented in `supabase/migrations/README.md`. Do not reset the database until a clean replayable baseline is reconstructed.
2. **Source/target schema mismatch:** The original source uses `daily_questions` and `attempt_submissions`; the new target uses `daily_challenges`, `daily_challenge_attempts`, and `jee_pyq_questions`. A source-to-target compatibility map is required.
3. **Content import incomplete:** The ZIP has 75 question slots; only 5 are in the target so far. All imported records are drafts, and no content is published. The manifest marks 28 questions as `needs_review`; their answer keys must stay withheld until review.
4. **Image assets not migrated:** 21 PNG/JPG files and manifest references were found in the ZIP. They need to be copied to the new app or new Storage bucket and visually verified before any dependent question is published.
5. **Security advisor warnings:** The latest advisor reports 11 authenticated-callable `SECURITY DEFINER` RPCs. They are intentional trusted operations and include explicit `auth.uid()` checks; the admin save RPC additionally checks server-managed admin metadata. Five private tables have RLS enabled without policies and no direct browser-role grants. Re-run advisors and review after each backend change.
6. **Admin bootstrap required:** No Auth users were supplied. Before the admin route can be used, create the owner account and assign `app_metadata.role = admin` through the Supabase Dashboard; never use user-editable metadata for authorization.
7. **Legacy Edge Functions:** `admin-cleanup` and `released-solution` from the original ZIP have not been ported/deployed to the new project.
8. **Live-site comparison:** The original GitHub Pages site still needs a successful browser inspection. The original production website remains untouched.

## Next actions

1. Finish the draft-only import of the remaining 70 question records and preserve source/QA metadata; keep all unresolved items unpublished.
2. Migrate the 21 image assets, validate every reference, and add a storage-access model that does not leak daily challenge content before release.
3. Recover or clearly label reconstructions for the seven missing applied migration bodies, then validate a baseline in an isolated disposable database.
4. Complete PYQ authoring/review/publishing, admin moderation, student practice, chapter filters and mock-test persistence.
5. Keep the green CI gates required on every change; next priority is completing the remaining legacy workflows and migrating the remaining question content/assets.
6. Obtain a real staging deployment, configure environment variables, and run authenticated student/admin E2E tests plus storage/security-negative tests.
7. Prepare rollback and production-launch checklist. Do not switch the live site without approval.

## Status vocabulary

- **Not started:** no implementation yet.
- **In progress:** implementation or audit underway.
- **Implemented:** code exists, but not yet proven.
- **Tested:** relevant automated/runtime tests have run.
- **Verified:** prescribed checks passed and evidence is recorded.
- **Blocked:** missing source, permissions, configuration or authoritative content prevents safe completion.

## Continuity implementation — 2026-10-24

- **Implemented:** added `docs/CONTINUITY_SYSTEM_PROMPT.md`, `docs/SESSION_HANDOVER.md`, and `docs/VERIFICATION_LOG.md`; created `scripts/check-continuity.mjs` to require core continuity files, detect duplicate permanent task IDs, and ensure the active handover task exists in the ledger; added the validator to GitHub Actions CI.
- **Verified:** the Supabase migration API currently returns 20 applied versions. Prior docs that reported 21 were inconsistent and have been corrected where found.
- **CI recovery:** run `40091156887` failed at Prettier, as suspected. The CI workflow was adjusted to format the identified continuity docs and validator on pushes to `main`, commit only those formatting files, then run the gates. Run `40091830452` passed continuity validation, lint, typecheck, Vitest, Playwright, Prettier, and production build; formatter commit `b6bb46d81ce81b803296aa6c9421ca611b03f8b3` was created successfully.
- **Verified:** continuity validator and full configured CI passed on the formatted working tree. **Not yet verified:** authenticated student/admin journeys, Vercel linkage/runtime, clean isolated migration replay.

**Current task:** BJ-DB-001 — reconstruct and safely replay the missing migration baseline in isolated staging.

## Continued work — 2026-10-24

- **Implemented (runtime verification pending):** protected `/admin/pyq` authoring and review workspace; Zod-validated server actions call database-owned admin RPCs; the dashboard lists recent question metadata without selecting private answer-key records; draft save, approve-as-draft, publish-with-confirmation, and unpublish controls are available.
- **Hardened and database-applied:** publishing now requires a source document and page, non-empty question statement, private answer key, worked solution, and (for single-correct questions) an answer matching an option label. Answer keys remain in the private schema; no draft was published by this change.
- **Reconciled:** reconstructed the already-applied `admin_pyq_authoring_review` database function definitions into `supabase/migrations/20261024103715_admin_pyq_authoring_review.sql` so the admin authoring backend is represented in Git.
- **Verified:** inspected target RLS policy for PYQs: students/anonymous users can select only approved published questions, while admin queue reads are gated by `app_metadata.role = admin`; the answer-key table remains private.
- **CI:** historical run `40088044408` passed before this reconstruction work. The latest reconstruction branch head `d15ba7d` is undergoing a fresh workflow; the last completed green run is `40112374432` on `f2831f8`. Re-check the latest head run before claiming the current branch is green.
- **Security hardening applied:** publishing a PYQ now requires a non-empty source reference, private answer key, and worked solution; the single-correct answer must still match an option. The migration is applied to the target Supabase project and checked into Git as `20261024111533_require_pyq_source_and_solution_before_publish.sql`.
- **Verified:** target RLS permits anonymous/student reads only for published approved PYQs; the private answer-key table has no direct `anon` or `authenticated` table grants; the three admin authoring/review RPCs are executable by `authenticated` only among browser roles and enforce admin app metadata inside the function.
- **Not verified:** admin PYQ authoring and review actions have not yet been exercised in a real authenticated browser session. No question has been published as part of this work.

- **Engineering improvement:** the repository has a committed npm lockfile and CI uses `npm ci` for reproducible dependency installation.
- **Latest reconstruction CI:** run `40113303240` passed both jobs on commit `7f81a08`: quality gates (continuity validation, lint, typecheck, unit tests, Playwright E2E, Prettier, production build) and disposable PostgreSQL replay, security catalog assertions, and four RPC denial tests.

## Constitution reconciliation — 2026-10-24

- **Implemented:** Added `docs/PROJECT_CONTEXT.md`, `docs/TASKS.md`, `docs/DECISIONS.md`, `docs/RELEASES.md`, `docs/SEO_AND_GROWTH.md`, and `CHANGELOG.md` to align the repository with the owner's engineering constitution.
- **Verified against live Supabase:** 20 migration versions are recorded by the project migration API; 15 SQL migration files exist in the repository. Seven applied migration bodies remain missing from the repository, and two local publication-gate files are absent from live migration history. Do not reset the target database.
- **Verified against live Supabase:** PYQ review RPC requires a source document and page, reads the private answer key, and requires a worked solution. Anonymous execute privilege is false; authenticated execute privilege is true, with admin role enforced inside the function.
- **Verified against live data:** 5 PYQ records total, 0 published, 5 unpublished. No content was imported or published during this reconciliation.
- **CI evidence:** [Run 40090330071](https://github.com/black-jee/blackjee/actions/runs/40090330071) passed for commit `57d04ed9d3db332e0aafe71d69423be5723c7ff5`. Documentation commits after that SHA triggered additional workflows; those latest runs must be checked before claiming the current HEAD is green.
- **Production verification:** the supplied URL `https://blackjee.vercel.app/` could not be fetched by the available web retrieval path. Vercel project linkage, deployed commit and runtime behavior remain unverified.
- **Next action:** verify the queued current-head CI; continue catalog-backed reconstruction without changing the live migration ledger; then perform a replay only when a no-cost disposable database is available. Production deployment linkage/runtime and real authenticated workflows remain unverified.

## Reconstruction branch checkpoint — 2026-10-24 (latest read-only verification)

- **Current branch:** `chore/schema-reconstruction`; draft PR [#2](https://github.com/black-jee/blackjee/pull/2) remains unmerged.
- **Latest observed CI run:** [40114721534](https://github.com/black-jee/blackjee/actions/runs/40114721534) — disposable `reconstruction-replay` **PASS**; `quality` was still **IN_PROGRESS** at the latest poll. Do not mark the whole run green until the quality job completes.
- **Latest Vercel status:** **FAIL / deployment unverified**, with the provider status linking to a build-rate-limit page. No paid upgrade was initiated.
- **Live Supabase recheck:** migration API returns 20 applied versions, including `20261024112132_require_pyq_source_page_before_publish`; no migration repair was attempted. The import Edge Function is listed active with JWT verification but its current handler returns HTTP 410 (retired).
- **Advisor review:** five private tables have RLS enabled without policies, consistent with the existing no-browser-USAGE/no-direct-table-access model; eleven authenticated-callable SECURITY DEFINER RPCs remain review notices. A missing index on `private.mock_test_responses.question_id` is a performance candidate, not an automatic production change. Seven indexes are flagged unused; do not drop without workload evidence.
- **Remaining release blockers:** recover the seven missing historical migration bodies or approve a separate canonical-baseline strategy; complete real authenticated student/admin browser tests; implement and verify Storage access safely; validate image mapping and source provenance; verify a real staging/production runtime. Source-content gaps remain blocked on authoritative evidence and QA—do not fabricate or publish.
- **Safety:** all latest Supabase queries were read-only. No live schema/data changes, Storage buckets, migration repair, content publication, paid infrastructure, or PR merge occurred.

## Reconstruction branch checkpoint — 2026-10-25 (verified current HEAD)

- **Branch / PR:** `chore/schema-reconstruction`; draft [PR #2](https://github.com/black-jee/blackjee/pull/2) is open and unmerged at `063cf1480d36f8c4c84efebb41438566122dc8c3`.
- **GitHub Actions:** [run 40155186509](https://github.com/black-jee/blackjee/actions/runs/40155186509) completed **PASS** for both `quality` and `reconstruction-replay` on that exact HEAD. This includes the repository's configured lint/typecheck/tests/format/build/security checks and the disposable PostgreSQL reconstruction replay. It does not establish live Supabase migration equivalence or real Supabase-issued user-token/browser authorization.
- **Vercel:** combined commit status still reports a deployment rate-limit/upgrade-page failure. Deployment/runtime remains unverified; no paid upgrade was attempted.
- **Migration inventory:** read-only reconciliation currently reports 20 applied live ledger entries and 19 repository SQL migration files (excluding README), with 13 exact version/name matches, seven live versions without same-version SQL bodies, and six repository SQL files absent from the live ledger. See `docs/MIGRATION_RECONCILIATION_2026-10-24.md`. Historical bodies remain unresolved; do not repair the ledger, rename migrations to imply historical identity, or apply the branch migrations to production.
- **Branch-only database hardening:** mock-test NULL validation, PYQ option-label validation, daily-challenge schedule NULL guards, and the `private.mock_test_responses(question_id)` index have disposable-replay/test coverage but are **not production-deployed**.
- **Authorization evidence:** synthetic-identity negative RPC tests pass in the disposable replay. Real Supabase-issued user-token tests and a dedicated live-vs-replay grants/policies diff remain outstanding.
- **Content and assets:** no new JEE question/answer/solution content was added by this reconstruction work. The existing five imported PYQs remain drafts per the last recorded live-data check; confirm live data again before relying on that count. Storage has no configured buckets/policies per the last read-only audit.
- **Safety boundary:** no production DDL, migration apply/repair/reset, content publication, paid infrastructure, or PR merge was performed.
- **Next engineering step:** deepen live-catalog-versus-reconstruction comparison (constraints, indexes, function ACLs, and policy expressions), record evidence versus inference, and keep all reconstruction artifacts separate from deployable migration history until a separately reviewed baseline plan exists.
