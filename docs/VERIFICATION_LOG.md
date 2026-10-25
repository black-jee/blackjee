## 2026-10-25 — CI run #659 and auth-test formatting correction

- **Commit tested by run #659:** `c63f0329806174300682311446af0b420ec927d3`.
- **GitHub Actions:** [run 40215878244](https://github.com/black-jee/blackjee/actions/runs/40215878244) — **FAIL** overall. `quality` failed at step `Check formatting`; logs named `tests/mock-test-action-auth.test.ts`. Earlier quality steps passed, including dependency audit, lint, typecheck, unit tests, 22 Playwright tests, and application build. `reconstruction-replay` **PASS** with all configured replay steps successful.
- **Correction:** commit `45832664ac395912257e1c7b5afcd6280c81b44b` (`test: correct auth assertion formatting`) restored the assertion to a single line that fits the repository's Prettier formatting. The follow-up handover commit is `717b53de2f4d90f4530d27efe3bfa20840346f80`.
- **Current verification:** CI for the corrected code and subsequent documentation commit is **UNVERIFIED** at the time of this entry; do not treat run #659 as a green result for the corrected HEAD.
- **Other status:** commit combined status showed Vercel pending, not verified deployment success. The older #650/#649 passes apply only to their listed SHAs.
- **Safety:** no production Supabase changes, migration-ledger repair, content publication, paid infrastructure, or PR merge occurred. PR #2 remains draft/open/unmerged.

# BLACK-JEE verification log

## 2026-10-25 — commit 4f635a9 / CI run #650

- **Commit tested:** `4f635a9fafde686c14a0a634f9864e24f11dd238` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40214488944](https://github.com/black-jee/blackjee/actions/runs/40214488944) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully.
- **Quality scope:** continuity validation, static security contracts, production dependency audit, lint, TypeScript typecheck, unit tests, Playwright desktop/mobile browser tests, Prettier formatting, and production build passed.
- **Reconstruction scope:** disposable PostgreSQL 17 replay and the configured catalog, RLS, RPC/grant, branch-only integrity/index, application-security, and RPC authorization-denial checks passed.
- **Limits:** this is documentation-only commit verification plus the configured CI suite. The replay does not recover the seven missing historical migration bodies or prove exact historical migration equivalence. Synthetic compatibility auth is not real Supabase-issued JWT verification; complete authenticated student/admin browser workflows and production runtime remain unverified.
- **Safety:** no production schema/data/grant/migration-ledger changes, question/solution additions, paid infrastructure, deployment action, or PR merge occurred. PR #2 remains open, draft, and unmerged.

## 2026-10-25 — commit f65d12d / CI run #649

- **Commit tested:** `f65d12d1657ca0daa09956442003c5e0cd0d58a9` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40214294126](https://github.com/black-jee/blackjee/actions/runs/40214294126) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully.
- **Quality scope:** legacy asset-import safety tests, continuity validation, static security contracts, production dependency audit, lint, TypeScript typecheck, unit tests, 22 Playwright desktop/mobile browser checks, Prettier formatting, and production build all passed.
- **Reconstruction scope:** disposable PostgreSQL 17 replay passed table-shape, constraint/index, RLS policy, routine definition/security, routine execute ACL, browser-role grant, application security, branch-only integrity/index, and RPC authorization-denial checks.
- **Limits:** the passing disposable replay does not recover the seven missing applied migration bodies or prove exact historical migration equivalence. Synthetic compatibility auth is not real Supabase-issued JWT verification; complete authenticated student/admin browser workflows remain outstanding. The production deployment/runtime is not certified by CI.
- **Safety:** no production schema/data/grant/migration-ledger changes, question/solution additions, paid infrastructure, deployment action, or PR merge occurred. PR #2 remains open and unmerged.

Record only checks that actually ran. Outcomes: **PASS**, **FAIL**, **SKIPPED**, **UNVERIFIED**. A successful check applies only to the commit/environment named.

## 2026-10-24 — repository CI

- **Continuity CI run:** [40091830452](https://github.com/black-jee/blackjee/actions/runs/40091830452), workflow-triggering commit `d69ba5fc32ec4a07f0e390ef51795e990795f5ab`; **PASS**. The continuity validator, npm ci, ESLint, TypeScript, Vitest, Playwright E2E, Prettier check, and production build all passed. The run applied Prettier formatting to seven Markdown files and `scripts/check-continuity.mjs`, then committed those formatting changes as `b6bb46d81ce81b803296aa6c9421ca611b03f8b3`. The formatting step and formatting commit both succeeded.

- **Commit:** `ec2f7ce1bfb25a0b1e96f3168ab82959c8a5af1e`
- **Workflow:** [CI run 40090784800](https://github.com/black-jee/blackjee/actions/runs/40090784800)
- **npm ci:** **PASS** — dependencies installed; npm reported four audit vulnerabilities (1 low, 1 moderate, 2 critical), requiring separate dependency review.
- **ESLint:** **PASS**.
- **TypeScript typecheck:** **PASS**.
- **Vitest:** **PASS**.
- **Playwright E2E:** **PASS**.
- **Prettier format check:** **FAIL** — workflow step `npm run format:check` failed.
- **Production build:** **SKIPPED** — workflow stopped after the format check failure.
- **Limitations:** this CI run does not verify authenticated real-user journeys, Vercel deployment/runtime, or production data behavior.

- **Older successful CI:** [run 40090330071](https://github.com/black-jee/blackjee/actions/runs/40090330071), commit `57d04ed9d3db332e0aafe71d69423be5723c7ff5`, **PASS** for configured gates at that older commit. It is not evidence that the current HEAD passes.

## 2026-10-24 — target Supabase PYQ publishing gate

- **Environment:** project ref `phdssyexhfyxsmhmmcgb`.
- **Check:** inspected `public.admin_review_jee_pyq_question(uuid,boolean,boolean,text[])` definition and function privileges.
- **Result:** **PASS** for static database definition/grant checks: source document and page required, private answer key and worked solution checked, single-correct option-label validation present, anonymous execute denied, authenticated execute granted to the guarded RPC.
- **Data state observed:** five PYQ records, zero published, five unpublished drafts.
- **Limitations:** no authenticated browser publish flow was executed; this is not a production browser test.

## 2026-10-24 — production deployment

- **URL:** https://blackjee.vercel.app/
- **Result:** **UNVERIFIED** — available retrieval did not provide page content or Vercel deployment metadata.
- **Limitations:** active project linkage, deployed commit, environment-variable presence, and runtime smoke checks remain unknown.

## 2026-10-24 — migration history

- **Result:** **UNVERIFIED pending reconciliation** — existing project documents disagree on the exact applied migration count. A prior direct Supabase query reported 20 applied versions, while a later context note reports 21. Re-query the live migration API before making the count authoritative.
- **Safety:** no reset or destructive migration was performed. Known discrepancy: applied history and checked-in migration files do not match, including missing baseline bodies.

## 2026-10-24 — migration reconciliation discovery

- **Outcome:** PASS for read-only discovery; migration reconstruction and isolated replay remain UNVERIFIED.
- **Evidence:** Supabase migration history returned 20 applied versions. Repository listing contains 15 SQL migration files, with live version `20261024112132_require_pyq_source_page_before_publish` absent and repository-only versions `20261024112500` and `20261024120000` not present in live history. See [`docs/MIGRATION_RECONCILIATION.md`](./MIGRATION_RECONCILIATION.md).
- **Schema inspected:** public base table/column inventory, public routines (definitions truncated for initial scan), public RLS policies, and public indexes. This is not yet a complete schema export.
- **Safety:** no DDL, migration apply, reset, row mutation, publication, or deployment action was performed.
- **CI:** run [40092001380](https://github.com/black-jee/blackjee/actions/runs/40092001380) succeeded, including continuity validation, lint, typecheck, unit tests, Playwright E2E, format check, and production build on workflow-triggering SHA `2195242d7b78cf52447ea2cd4fab83d30c834440`.

## 2026-10-24 — CI formatter repair and schema inventory

- **CI run:** [40092920061](https://github.com/black-jee/blackjee/actions/runs/40092920061) — PASS on workflow commit `7ee443192d6740d1892978dc09d8c3fe226a1c8f`. Continuity validation, npm ci, lint, typecheck, unit tests, Playwright E2E, format check, and production build all completed successfully.
- **Cause of intervening CI failures:** first the expanded database documents were not included in the formatter list; after widening the list, the staging command used a quoted Git pathspec that matched no files. The workflow now formats all root and `docs/` Markdown files and stages the formatter-only changes with `git add -A` in the clean CI checkout.
- **Read-only database findings:** all four public application tables and five private application tables have RLS enabled (not forced); no non-internal application triggers were found; no explicit private-schema policies were found; and `storage.buckets` contains zero rows with no storage policies. See `docs/MIGRATION_RECONCILIATION.md`.
- **Status:** migration reconstruction and replay remain UNVERIFIED. No target DDL/data changes were made. An isolated Supabase development branch has not been created because branch provisioning may incur charges and requires owner cost approval.

## 2026-10-24 — current repository hardening follow-up

- **CI run:** [40097841411](https://github.com/black-jee/blackjee/actions/runs/40097841411) — **PASS** on workflow-triggering commit `e50a518f43613fd1d022a90d5935a4846b8d0a5f`. Continuity validation, dependency installation, lint, typecheck, unit tests, Playwright E2E, format check, and production build passed. The source files were Prettier-formatted during this run and committed to `main` as `83cc895c45db7cf41e1db3e741a862c9d6371358`; this run tested the formatted working tree, and a new read-only CI workflow was then committed to remove branch-mutating formatter behavior.
- **CI workflow hardening:** commit `e50a518f43613fd1d022a90d5935a4846b8d0a5f` changes CI to `contents: read`, removes formatter auto-commits, and makes formatting a normal gate. Fresh CI for this exact commit passed.
- **Privileged RPC catalog contract:** added `supabase/tests/security_definer_rpc_contracts.sql`. Executed the same catalog-only assertions against the target project; **PASS** for all 11 expected RPC signatures, `SECURITY DEFINER`, pinned empty `search_path`, no anonymous execute privilege, authenticated execute privilege, `auth.uid()` checks, and server-managed admin metadata checks on the three admin RPCs. The assertion block reads catalog/function definitions only; no application data was changed.
- **Still unverified:** migration replay equivalence, authenticated browser student/admin journeys, deployment runtime, and end-to-end cross-user negative tests. The SQL contract file is a manually runnable database regression assertion; it is not yet wired into the standard npm CI because CI has no disposable PostgreSQL/Supabase service.
- **Safety:** no DDL, migration apply/repair, row mutation, question publication, paid infrastructure, or production deployment was performed.

## 2026-10-24 — latest main-branch verification

- **CI:** [run 40098020175](https://github.com/black-jee/blackjee/actions/runs/40098020175) — **PASS** on `b4d23d1b6a5d5a3a629e2f32485ce4c233abe824`; quality job completed successfully.
- **GitHub Pages workflow:** [run 40098020314](https://github.com/black-jee/blackjee/actions/runs/40098020314) — **PASS** for the same commit. This is workflow status only; it does not verify Vercel deployment linkage or authenticated production behavior.
- **Documentation maintenance:** migration reconciliation now records the inspected repository HEAD and these run results. This documentation-only commit does not resolve the missing migration bodies or version drift; isolated replay remains **UNVERIFIED**.
- **Safety:** no production schema/data changes, migration apply/repair/reset, content publication, or paid infrastructure was used.

## 2026-10-24 — migration recovery log formatting and continuity refresh

- **CI:** [run 40101029806](https://github.com/black-jee/blackjee/actions/runs/40101029806) — **PASS** on commit `78e6c72b`; continuity validation, dependency install, lint, typecheck, unit tests, Playwright E2E, Prettier check, and production build all passed.
- **GitHub Pages workflow:** [run 40101029607](https://github.com/black-jee/blackjee/actions/runs/40101029607) — **PASS** for the same commit. This confirms workflow success only, not Vercel project linkage or authenticated production behavior.
- **Migration recovery:** `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md` records seven applied migration bodies not found in the checked repository history/indexed search. No SQL was inferred from migration names; clean replay remains **UNVERIFIED**.
- **Safety:** documentation-only changes. No target DDL/data changes, migration apply/repair/reset, publication, or paid infrastructure.

## 2026-10-24 — current reconstruction branch and live advisor recheck

- **GitHub Actions CI:** [run 40114452358](https://github.com/black-jee/blackjee/actions/runs/40114452358) on reconstruction HEAD `696f965918f18b4629ceca912b00fbf58466b140` — **PASS**. Both `quality` and `reconstruction-replay` jobs completed successfully. The replay uses disposable PostgreSQL in GitHub Actions, not the live Supabase project.
- **Vercel status:** **FAIL / external deployment blocked** — the commit status points to Vercel's `upgradeToPro=build-rate-limit` page. This does not prove the app itself is broken, but the latest Vercel deployment is not verified and may be blocked by a build-rate limit. No upgrade or paid service was initiated.
- **Live migration inventory:** **PASS, read-only** — Supabase returned 20 applied migration versions. The same seven historical migration bodies remain missing from Git; the live ledger includes `20261024112132_require_pyq_source_page_before_publish`. No migration was applied or repaired.
- **Live Supabase security advisor:** **REVIEW REQUIRED, read-only** — five private tables are RLS-enabled without policies; the current model intentionally relies on the private schema being inaccessible to browser roles and controlled RPC access. Eleven authenticated-callable SECURITY DEFINER RPCs remain flagged; catalog regression assertions cover pinned search paths, auth checks, grants and function-definition fingerprints. Re-review these warnings after backend changes rather than suppressing them.
- **Live Supabase performance advisor:** one unindexed foreign key remains on `private.mock_test_responses.question_id`; seven indexes are reported unused. No index was added or removed because workload evidence is insufficient for a safe performance change.
- **Edge Function audit:** `one-time-pyq-import` is listed ACTIVE with JWT verification enabled, but the deployed handler responds only with HTTP 410 and the message that the endpoint has been retired. **PASS for retired handler content**; do not treat ACTIVE metadata alone as evidence that import is available.
- **Safety:** these checks were read-only. No live DDL, data mutation, content publication, Storage bucket creation, paid infrastructure, or deployment action was performed. Authenticated browser journeys and production runtime remain **UNVERIFIED**.

## 2026-10-25 — reconstruction branch HEAD verification

- **Commit tested:** `063cf1480d36f8c4c84efebb41438566122dc8c3`.
- **GitHub Actions:** [run 40155186509](https://github.com/black-jee/blackjee/actions/runs/40155186509) — **PASS** for both `quality` and `reconstruction-replay` jobs. This is the verified result for that SHA only.
- **Scope limits:** the replay uses disposable PostgreSQL 17 and a compatibility auth surface; synthetic-identity authorization checks are not equivalent to real Supabase-issued user-token tests. It does not prove that reconstructed SQL is byte-for-byte or historically equivalent to the missing applied migrations.
- **Deployment status:** the combined GitHub commit status still reports a Vercel build-rate-limit/upgrade-page failure. Deployment/runtime remains **UNVERIFIED**; no paid upgrade was attempted.
- **Production safety:** no production DDL, migration apply/repair/reset, content publication, or deployment was performed for this verification.
- **Follow-up documentation:** the current-head checkpoint was added to `docs/PROJECT_STATUS.md` in commit `0758f03385f153d28853a40b33caa40b3331bea8`. That new documentation commit needs its own CI run before it can be called green.

## 2026-10-25 — exact daily-challenge RPC baseline and CI verification

- **GitHub Actions:** [run 40165662614](https://github.com/black-jee/blackjee/actions/runs/40165662614) — **PASS** for both `quality` and `reconstruction-replay` at commit `12548bf6bb499ac806124b09dc29af93d3a0cac4`.
- **Baseline:** the branch reconstruction now uses the read-only live `pg_get_functiondef` for `public.admin_save_daily_challenge`; captured MD5 is `ebdff78aa677719515c9e500fc576562`. CI asserts this baseline before applying branch-only hardening.
- **Test correction:** security-contract checks now locate solution/option integrity rules in `20261025110000_harden_daily_challenge_authoring_integrity.sql`, not in the original live baseline.
- **Fresh live read-only query:** 20 migration ledger rows; live function MD5 matches the captured fingerprint; production has zero `validate_jee_pyq_option_labels` triggers and zero standalone indexes matching `private.mock_test_responses(question_id)`. These two hardening changes remain branch-only.
- **Limits:** this verifies one RPC baseline and branch CI, not the full production catalog, missing historical SQL bodies, real Auth-issued JWT behavior, or deployment/runtime.
- **Safety:** no production DDL, grants, row changes, migration repair, publication, paid infrastructure, or PR merge occurred.

## 2026-10-25 — latest verified reconstruction CI

- **Commit tested:** `bb0d19bb58e09c7dba41892a7d0c571d08155579` (`chore/schema-reconstruction`).
- **GitHub Actions:** [run 40166741350](https://github.com/black-jee/blackjee/actions/runs/40166741350) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully. Quality gates passed: static security contracts, production dependency audit, lint, typecheck, unit tests, Playwright E2E, formatting, and production build. Reconstruction replay passed on disposable PostgreSQL 17, including catalog/RLS/RPC/grant assertions, branch-only hardening tests, application security assertions, and RPC authorization-denial tests.
- **Deployment status:** the commit's combined GitHub status still reports **Vercel failure** linking to the build-rate-limit/upgrade page. Do not treat CI success as deployment success. No paid upgrade was attempted.
- **Boundaries:** the CI replay does not recover missing historical migration bodies, prove production migration-chain replay or full live-catalog parity, or replace real Supabase-issued JWT/user-token and student/admin browser tests.
- **Safety:** this verification involved repository CI only. No production SQL/DDL, migration repair, production data changes, content publication, paid infrastructure, or PR merge occurred.

## 2026-10-25 — browser recovery tests and reconstruction CI

- **Commit tested:** `731a835d1ad3e89e343984a043d94c83b3d41b2e` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40168181107](https://github.com/black-jee/blackjee/actions/runs/40168181107) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully.
- **Quality scope:** static security contracts, production dependency audit, lint, TypeScript, unit tests, Playwright browser smoke tests, Prettier formatting, and production build passed. The password-update mismatch test now targets the form paragraph with `p[role="alert"]`, avoiding ambiguity with framework route-announcer alerts.
- **Reconstruction scope:** disposable PostgreSQL 17 replay, reconstructed catalog/RLS/RPC/grant assertions, branch-only integrity hardening tests, application security regression assertions, and RPC authorization-denial tests passed.
- **Limits:** this does not recover the seven missing historical migration bodies, prove exact live catalog/migration parity, test real Supabase-issued JWTs, or validate deployed Vercel runtime/authenticated end-to-end flows. Vercel deployment remains separately unverified due to the previously observed build-rate-limit/upgrade status.
- **Safety:** repository-only test/configuration and documentation changes. No production SQL/DDL, migration repair/reset, data changes, question/solution additions, paid infrastructure, deployment, or PR merge.

## 2026-10-25 — password-reset neutral error handling and browser CI

- **Commit tested:** `703c803be479905ba4f5f7e89c622a182757d401` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40169013572](https://github.com/black-jee/blackjee/actions/runs/40169013572) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully.
- **Browser coverage:** all 12 Playwright executions passed across desktop Chromium and mobile Chromium. Coverage includes the home page, sign-in controls, password-reset page, neutral password-reset success, neutral provider-failure handling, and mismatched-password rejection.
- **Security improvement:** password-reset failures now display a generic message instead of raw provider error text. CI supplies isolated dummy public Supabase configuration to browser tests so reset-flow tests exercise the client request rather than only the missing-configuration fallback. The test asserts the form paragraph specifically to avoid framework route-announcer role ambiguity.
- **Quality scope:** dependency audit, lint, typecheck, unit tests, E2E tests, Prettier formatting, and production build passed. Disposable PostgreSQL reconstruction replay and its catalog/security assertions passed.
- **Limits:** this does not recover the seven missing historical migration bodies, prove exact live catalog parity, validate real Supabase-issued JWTs, or verify the deployed Vercel runtime. The Vercel status remains rate-limited and no paid upgrade was attempted.
- **Safety:** only repository source, tests, CI configuration, and documentation were changed. No production DDL/data changes, migration repair/reset, question/solution additions, paid infrastructure, deployment, or PR merge occurred.

## 2026-10-25 — follow-up deployment status

- **Commit checked:** `9e7f12c908f6277774d4988a783001d1a124e552` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40169200820](https://github.com/black-jee/blackjee/actions/runs/40169200820) — **PASS** for both quality and reconstruction replay.
- **Vercel:** the GitHub commit status now reports **deployment completed** for this commit. The generated preview URL is [blackjee-git-chore-schema-reconstruction-black-jee.vercel.app](https://blackjee-git-chore-schema-reconstruction-black-jee.vercel.app/). Automated page retrieval through the available web reader was inaccessible, so this confirms deployment status and URL availability in Vercel's status—not a manual verification of every live route.
- **PR state:** PR #2 remains open, draft, and unmerged. No paid upgrade was attempted.

## 2026-10-25 — live Supabase advisor recheck

- **Scope:** read-only Supabase security/performance advisor queries plus `pg_proc` inspection; no DDL, grants, or row changes were made.
- **Security advisors:** five private-schema tables are RLS-enabled without policies. These tables hold answer keys, answer attempts, mock responses, or private sessions and are intentionally accessed through guarded RPCs; do not add broad policies simply to silence the advisor.
- **Security-definer RPCs:** the advisor flags 11 public functions as executable by `authenticated`. Read-only catalog inspection confirmed all 11 use an empty `search_path`, none are executable by `anon`, admin authoring/review functions check the signed-in user and `auth.jwt()->app_metadata->role = 'admin'`, and student RPCs check authentication plus relevant ownership/publication/release conditions. This is a reason to retain negative authorization tests, not to revoke all authenticated execution blindly.
- **Performance advisor:** the live database still reports no covering index for `private.mock_test_responses(question_id)`. A branch-only migration `20261025120000_add_mock_test_response_question_id_index.sql` and disposable-replay regression test already address it, but the migration has **not** been applied to production. Seven indexes are reported unused; do not drop them without workload evidence.
- **Limits:** catalog source inspection is not a substitute for real Supabase-issued JWT tests and an end-to-end authorization audit. The seven missing historical migration bodies remain unrecovered.
- **Safety:** no production schema/data/grant changes, no paid infrastructure, no content publication, and no PR merge.

## 2026-10-25 — daily solution identity guard regression

- **Commit tested:** `4f10136bc4be5e0dd237514715633a7d1968965e` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40171137953](https://github.com/black-jee/blackjee/actions/runs/40171137953) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully; lint, typecheck, unit tests, Playwright E2E, formatting, production build, and disposable PostgreSQL reconstruction/security tests passed.
- **New runtime regression:** the disposable replay now verifies that a database session using role `authenticated` but carrying no signed-in user identity cannot retrieve daily-challenge solution data. The assertion passed before any challenge lookup. The fixture uses a synthetic UUID and adds no question, answer key, or worked solution.
- **Deployment status:** GitHub reports the Vercel deployment completed for this commit. This is provider status only, not independent verification of every live route or authenticated flow.
- **Safety:** no production SQL/DDL or data changes, no migration repair/reset, no new JEE content, no paid upgrade, and no PR merge.

## 2026-10-25 — password-update error handling and latest CI

- **Commit tested:** `2dfcbc8db0fb423bb41897a6f826f325b0b68bb3` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40172747201](https://github.com/black-jee/blackjee/actions/runs/40172747201) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully.
- **Quality scope:** static security contract checks, production dependency vulnerability audit, lint, TypeScript typecheck, unit tests, Playwright E2E, Prettier format check, and production build all passed.
- **Database replay scope:** disposable PostgreSQL reconstruction, catalog/RLS/RPC/grant assertions, branch-only mock-test NULL validation, PYQ option-label integrity, daily-challenge authoring integrity, mock-test response question index, application security assertions, and RPC authorization-denial tests all passed.
- **Application change:** password-update failures now display a neutral message rather than exposing raw authentication-provider/session errors. The user is directed to request a new reset link.
- **Limits:** this CI does not recover the seven missing historical migration bodies, prove exact live schema/migration parity, validate real Supabase-issued JWTs, or independently verify deployed authenticated student/admin journeys.
- **Safety:** repository-only change. No production SQL/DDL/data change, migration repair/reset, content publication, paid infrastructure, deployment action, or PR merge.

## 2026-10-25 — latest reconstruction CI verified

- **Commit tested:** `fb82e5c3dcec4127c11ea9ee2840b4c3d3404dc1` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40175995526](https://github.com/black-jee/blackjee/actions/runs/40175995526) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully.
- **Quality scope:** static security contract checks, production dependency vulnerability audit, lint, TypeScript typecheck, unit tests, Playwright E2E, Prettier formatting, and production build passed.
- **Reconstruction scope:** disposable PostgreSQL 17 replay passed table-shape, RLS, RPC, grants, baseline fingerprints, branch-only integrity/index tests, application security assertions, and RPC authorization-denial tests.
- **Application validation:** PYQ authoring schema now rejects duplicate option IDs, duplicate case-insensitive labels, fewer than two options for single-correct questions, and a correct answer absent from the option labels. Numerical questions with no options remain valid.
- **Limits / blockers:** this run does not recover the seven missing historical migration bodies, prove complete live-catalog/migration parity, validate real Supabase-issued JWTs, or independently prove current deployed runtime/authenticated student-admin journeys. Branch-only database hardening is not production-applied.
- **Safety:** no production DDL/data/grant changes, migration repair/reset, question/solution additions, paid resources, deployment action, or PR merge occurred. Draft PR #2 remains open and unmerged.

## 2026-10-25 — exact RLS and browser grant contracts

- **Commit tested:** `aa9270785137e4242ba66aaa12b382edaad038d7` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40177773683](https://github.com/black-jee/blackjee/actions/runs/40177773683) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully.
- **New RLS contract:** all 10 public policy definitions matched the captured live snapshot, including policy mode, role set, command, `USING`, and `WITH CHECK` expressions.
- **New grant contract:** browser-role SELECT column boundaries for daily challenges and PYQ questions, attempt-table read privileges, authoring write privileges, anonymous write denial, and public-schema usage/create privileges matched the reviewed contract.
- **Existing replay scope:** exact column, constraint/index, and routine fingerprints; RPC grant/security assertions; branch-only hardening tests; and synthetic RPC authorization-denial tests all passed.
- **Quality scope:** dependency audit, lint, TypeScript typecheck, unit tests, 14 Playwright browser tests, Prettier formatting, and production build passed.
- **Limits:** this remains a disposable replay, not a production mutation. It does not prove real Supabase-issued JWT behavior, every deployed browser journey, or recovery of the seven historical migration bodies. The six repository-only migration files remain unresolved.
- **Safety:** no production SQL/DDL/data/grant changes, migration repair/reset, JEE content additions, paid resources, deployment action, or PR merge occurred.

## 2026-10-25 — exact table/schema grants and RPC execute ACLs

- **Commit tested:** `0b11db500d37718d736f1b9a84597208fa287e66` on `chore/schema-reconstruction`.
- **GitHub Actions:** [run 40183570563](https://github.com/black-jee/blackjee/actions/runs/40183570563) — **PASS**. Both `quality` and `reconstruction-replay` completed successfully.
- **Public grant contract:** exact effective table-level privileges for `anon`, `authenticated`, and `service_role` on all four public application tables; approved column-level SELECT sets for challenge/PYQ tables; public/private schema USAGE/CREATE boundaries; and no direct privileges on private tables for browser/service roles.
- **Routine execute contract:** all 12 public RPCs checked for effective EXECUTE privileges and absence of `PUBLIC` EXECUTE. Only the schedule RPC is anonymously callable; all 12 are available to authenticated and service roles.
- **Quality scope:** dependency audit, lint, TypeScript typecheck, unit tests, Playwright browser tests, formatting, and production build passed.
- **Limits:** replay remains disposable PostgreSQL with stub auth functions; this is not a substitute for real Supabase-issued JWT/browser authorization testing or a complete catalog parity comparison.
- **Safety:** no production SQL/DDL/data/grant changes, migration repair/reset, JEE content additions, paid resources, deployment action, or PR merge occurred.

## 2026-10-25 — current branch CI run #611

- **Commit tested:** `c79d5b3d6b7a2cb9773823e4c6ab023e35194171`.
- **CI:** [run 40185258884](https://github.com/black-jee/blackjee/actions/runs/40185258884) — **PASS** for both `quality` and `reconstruction-replay`.
- **Quality scope:** continuity/static security checks, `npm ci`, production dependency audit, lint, typecheck, unit tests, Playwright browser tests, Prettier check, and production build all passed.
- **Replay scope:** disposable PostgreSQL replay passed captured table/column, constraint/index, RLS policy, routine definition/security attributes, routine ACL, browser-role grants, and catalog contracts. Runtime negative tests passed for anonymous/admin RPC denials, student/admin claim separation, mock-test NULL input rejection, cross-user mock-attempt resume/submit/result denial, private schema isolation, and synthetic challenge authoring integrity.
- **Limits:** these tests use a disposable PostgreSQL compatibility auth surface and synthetic identities; they are not a real Supabase-issued JWT/browser verification and do not establish historical equivalence of missing migration bodies.
- **Outstanding release gates:** seven applied migration bodies remain unrecovered, six repository-only migrations remain unreconciled, real authenticated student/admin journeys remain unverified, remaining question/image migration and review are incomplete, and deployment/runtime/rollback remain unverified.
- **Safety:** PR #2 remains draft/open/unmerged. No production schema/data/grants/migration ledger changes, question/solution additions, paid infrastructure, or deployment action occurred in this verification.
