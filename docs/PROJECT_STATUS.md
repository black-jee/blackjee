# BLACK-JEE project status

**Last updated:** 2026-10-24  
**Overall status:** In progress — core application routes and secure database workflows are being built. Not production-ready.

## Environment

| Item                    | Observed status                                                                                                                 |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| New GitHub repository   | `black-jee/blackjee`, public, default branch `main`                                                                             |
| New Supabase            | `phdssyexhfyxsmhmmcgb`, ACTIVE_HEALTHY, PostgreSQL 17.11, Tokyo region                                                          |
| Supabase migrations     | 18 applied entries; 12 new migration files are checked into Git, while six original migration bodies remain to be reconstructed |
| Supabase data           | 5 PYQ rows imported as drafts, 5 private answer keys, 0 published questions; 70 source questions remain to be imported          |
| Supabase tables         | 9 inspected public/private tables; no student attempts or mock-test attempts                                                    |
| Supabase Edge Functions | Original source functions are not deployed. A temporary import endpoint is retired (JWT required, returns HTTP 410)             |
| Legacy source ZIP       | Readable; 84 files total, including 75 question slots in the April 4 Shift 1 manifest and 21 image files                        |
| Live website comparison | Blocked/incomplete; direct fetch did not return page content                                                                    |

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
- **CI run 40087443743:** ESLint, strict TypeScript, Vitest, Playwright browser tests, and the Next.js production build passed. The final Prettier check failed for `docs/PROJECT_STATUS.md` and `tsconfig.json`. A second formatting pass and a fresh full CI run are pending.
- **Dependency reproducibility:** `package-lock.json` is committed and CI uses `npm ci`; final confirmation is pending from a fresh CI run.
- **Not verified:** Browser behavior, real authenticated student/admin workflows, file upload/storage, full question import, and staging deployment.

## Important findings / blockers

1. **Migration history gap:** The new repository does not contain the six original SQL migration bodies already recorded in the target project. The gap is documented in `supabase/migrations/README.md`. Do not reset the database until a clean replayable baseline is reconstructed.
2. **Source/target schema mismatch:** The original source uses `daily_questions` and `attempt_submissions`; the new target uses `daily_challenges`, `daily_challenge_attempts`, and `jee_pyq_questions`. A source-to-target compatibility map is required.
3. **Content import incomplete:** The ZIP has 75 question slots; only 5 are in the target so far. All imported records are drafts, and no content is published. The manifest marks 28 questions as `needs_review`; their answer keys must stay withheld until review.
4. **Image assets not migrated:** 21 PNG/JPG files and manifest references were found in the ZIP. They need to be copied to the new app or new Storage bucket and visually verified before any dependent question is published.
5. **Security advisor warnings:** The advisor reports nine authenticated-callable `SECURITY DEFINER` RPCs. They are intentional trusted operations and include explicit `auth.uid()` checks; the admin save RPC additionally checks server-managed admin metadata. Five private tables have RLS enabled without policies and no direct browser-role grants. Re-run advisors and review after each backend change.
6. **Admin bootstrap required:** No Auth users were supplied. Before the admin route can be used, create the owner account and assign `app_metadata.role = admin` through the Supabase Dashboard; never use user-editable metadata for authorization.
7. **Legacy Edge Functions:** `admin-cleanup` and `released-solution` from the original ZIP have not been ported/deployed to the new project.
8. **Live-site comparison:** The original GitHub Pages site still needs a successful browser inspection. The original production website remains untouched.

## Next actions

1. Finish the draft-only import of the remaining 70 question records and preserve source/QA metadata; keep all unresolved items unpublished.
2. Migrate the 21 image assets, validate every reference, and add a storage-access model that does not leak daily challenge content before release.
3. Reconstruct the six original migration bodies into a replayable, version-controlled baseline and test on an isolated staging database.
4. Complete PYQ authoring/review/publishing, admin moderation, student practice, chapter filters and mock-test persistence.
5. Resolve the remaining Prettier gate on the current tree, then rerun all CI checks against the exact final commit.
6. Obtain a real staging deployment, configure environment variables, and run authenticated student/admin E2E tests plus storage/security-negative tests.
7. Prepare rollback and production-launch checklist. Do not switch the live site without approval.

## Status vocabulary

- **Not started:** no implementation yet.
- **In progress:** implementation or audit underway.
- **Implemented:** code exists, but not yet proven.
- **Tested:** relevant automated/runtime tests have run.
- **Verified:** prescribed checks passed and evidence is recorded.
- **Blocked:** missing source, permissions, configuration or authoritative content prevents safe completion.

## Continued work — 2026-10-24

- **Implemented (runtime verification pending):** protected `/admin/pyq` authoring and review workspace; Zod-validated server actions call database-owned admin RPCs; the dashboard lists recent question metadata without selecting private answer-key records; draft save, approve-as-draft, publish-with-confirmation, and unpublish controls are available.
- **Reconciled:** reconstructed the already-applied `admin_pyq_authoring_review` database function definitions into `supabase/migrations/20261024103715_admin_pyq_authoring_review.sql` so the admin authoring backend is represented in Git.
- **Verified:** inspected target RLS policy for PYQs: students/anonymous users can select only approved published questions, while admin queue reads are gated by `app_metadata.role = admin`; the answer-key table remains private.
- **CI:** a one-time repository formatting commit and `package-lock.json` are present. CI run `40087443743` passed lint, typecheck, unit tests, Playwright smoke tests and build, but the final format check still flagged `docs/PROJECT_STATUS.md` and `tsconfig.json`; these must be formatted and rechecked.
- **Not verified:** admin PYQ authoring and review actions have not yet been exercised in a real authenticated browser session. No question has been published as part of this work.

- **Engineering improvement:** the repository now has a committed npm lockfile. CI is being switched to `npm ci` so dependency installation is reproducible.
