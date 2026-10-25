# BLACK-JEE session handover

**Updated:** 2026-10-25  
**Active task:** BJ-DB-001 — continue free recovery of missing applied migration SQL; CI run #668 is green and PR #2 verification metadata is current  
**Branch:** `chore/schema-reconstruction`  
**Repository:** https://github.com/black-jee/blackjee  
**Supabase target:** `phdssyexhfyxsmhmmcgb`  
**Production URL supplied by owner:** https://blackjee.vercel.app/ (deployment linkage and runtime not verified)

## Latest verified state

- Current reconstruction PR #2 HEAD: `1a42455e41393c9f66b36d9c9ecb63466223f3b5` (`docs: refresh handover with green CI run 666`). CI run #668 ([40217791906](https://github.com/black-jee/blackjee/actions/runs/40217791906)) passed both `quality` and `reconstruction-replay`. Run #666 separately confirmed the Prettier correction in `tests/mock-test-action-auth.test.ts`. PR #2 verification description now cites run #668; PR remains draft/open/unmerged.

- Latest observed `main` HEAD: [`185a0ec9`](https://github.com/black-jee/blackjee/commit/185a0ec9612130980f96caa865df25daaebb31e2) — `docs: correct foundation audit migration counts`.
- CI run [40103159838](https://github.com/black-jee/blackjee/actions/runs/40103159838) passed on that commit. GitHub Pages workflow [40103159334](https://github.com/black-jee/blackjee/actions/runs/40103159334) also passed. These verify repository workflows only, not Vercel production runtime.
- The previous docs commit `73f7609d` also passed CI [40103034856](https://github.com/black-jee/blackjee/actions/runs/40103034856) and Pages [40103034659](https://github.com/black-jee/blackjee/actions/runs/40103034659).
- Supabase migration history contains 20 applied versions. Seven applied SQL bodies are missing from the repository: six baseline bodies and `20261024112132_require_pyq_source_page_before_publish`.
- Repository has 15 migration files, 13 exact filename/version matches, and two local-only files (`20261024112500`, `20261024120000`) not recorded as applied in the live history. Do not treat either local-only file as the missing `20261024112132` original.
- Public repository indexed searches and exact-path Git history checks did not recover the seven missing originals. The older reference repository `bhavishyacodz/BLACK-JEE` has a different schema and migration lineage; it is not authoritative for reconstruction.
- Latest read-only Supabase advisor scan (observed 2026-10-24 around 14:39 UTC) reported five informational private-table RLS/no-policy notices, eleven authenticated SECURITY DEFINER warnings, one informational unindexed FK (`private.mock_test_responses.question_id`), and seven informational unused-index suggestions. These findings need contextual review; do not blanket-revoke RPCs or drop indexes.
- The owner has no budget for paid infrastructure: **do not create a Supabase branch/project or incur infrastructure charges**.
- No production DDL, migration apply/repair, reset, row mutation, question publication, or paid infrastructure creation was performed during this work.

## Current work and blockers

### BJ-DB-001 — migration recovery and replay

- Inventory and recovery evidence: `docs/MIGRATION_RECONCILIATION.md`, `docs/MIGRATION_CHAIN_INVENTORY.md`, `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`, and `docs/FOUNDATION_AUDIT_2026-10-24.md`.
- Current state: historical SQL recovery remains blocked; clean replay remains unverified. Do not run `supabase db reset`, `migration repair`, or ad hoc DDL against the target.
- The safe path is to recover original SQL from owner-controlled local folders, older clones, archives, or backups. If unavailable, separately label reconstructed equivalents and compare them against read-only catalog evidence.
- Do not assemble a temporary replay workflow until the canonical migration sequence is replayable. Once it is, use a disposable PostgreSQL service in GitHub Actions with no production credentials and no paid Supabase resources.

### Security and authenticated journeys

- `docs/SECURITY_DEFINER_REVIEW_2026-10-24.md` records read-only function/grant inspection and remaining security tests.
- Authenticated cross-user isolation, ordinary-user denial of admin actions, and daily-solution/PYQ release boundaries still need runtime tests in an isolated setup. Do not create or publish real content for testing.
- `get_daily_challenge_result` currently appears to return the released answer/solution to any authenticated caller who knows the challenge ID after release time; it does not require prior participation. This may be intentional for learning after release. Confirm product policy and test before changing it.
- The `private.mock_test_responses.question_id` foreign key lacks a leading-key index. Consider a versioned index only after migration lineage is reconciled and expected workload is reviewed. Do not drop indexes just because a small/young database has low observed usage.

### Content and deployment

- Five PYQs are drafts and zero are published. The official April 4 Shift 1 source PDF is missing; keep unresolved content unpublished.
- Vercel project linkage, active deployed commit, environment-variable presence, and production smoke behavior remain unverified. Never print secret values.
- The source archive lists 75 question slots (47 marked `content_added`, 28 `needs_review`); reconcile each against an authoritative source before import or publication.

## Single exact next action

Continue with a no-cost, read-only repository review and test-plan preparation while the missing original SQL is searched for locally. Do not claim clean replay is possible until the seven missing bodies are recovered or a separately labelled reconstructed baseline is ready for review. Do not touch the live database or create paid infrastructure.

## Safe operating rules

1. Treat live Supabase checks as read-only until a separately reviewed change is explicitly approved.
2. Never expose service-role keys, passwords, or environment-variable values in logs or client-side variables.
3. Never fabricate missing migration SQL or question content.
4. Use free, isolated test environments only; the owner cannot afford a paid Supabase branch.
5. Update this handover and `docs/TASKS.md` when verified evidence changes.
