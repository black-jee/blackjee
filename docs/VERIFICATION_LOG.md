# BLACK-JEE verification log

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
