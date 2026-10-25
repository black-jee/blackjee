# BLACK-JEE session handover

**Updated:** 2026-10-26  
**Active task:** BJ-DB-001 — continue free recovery of missing applied migration SQL; CI run #671 is green and PR #2 verification metadata is current  
**Branch:** `chore/schema-reconstruction`  
**Repository:** https://github.com/black-jee/blackjee  
**Supabase target:** `phdssyexhfyxsmhmmcgb`  
**Production URL supplied by owner:** https://blackjee.vercel.app/ (deployment linkage and runtime not verified)

## Latest verified state

- Current PR #2 HEAD: `f40883f0b5f913843bc388ece559c23ae18e65f0`; CI [#677 / 40243544031](https://github.com/black-jee/blackjee/actions/runs/40243544031) passed both `quality` and `reconstruction-replay`.
- Five missing applied migration bodies were recovered byte-for-byte from Library archive `blackjee-foundation.zip` and restored under their exact versioned filenames. Hashes and provenance are in `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`.
- Current inventory: 20 live migration versions; 24 repository SQL files; 18 exact filename/version matches; two applied bodies remain missing; six repository-only files remain absent from live history.
- Unresolved: `20261024081337_numeric_answers_and_admin_review` (archive only has near-match version `20261024081110`) and `20261024112132_require_pyq_source_page_before_publish`. Do not relabel either near-match.
- Vercel GitHub status reports deployment completed for the current commit; live runtime/browser smoke test remains unverified.
- PR #2 remains draft/open/unmerged. Refresh PR verification after the next green CI run. No production schema/data/grants/migration-history changes or paid infrastructure were used.

## Current work and blockers

### BJ-DB-001 — migration recovery and replay

- Current evidence: `docs/MIGRATION_RECONCILIATION.md`, `docs/MIGRATION_CHAIN_INVENTORY.md`, `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`, and `docs/VERIFICATION_LOG.md`.
- Five exact-version SQL bodies have been restored from `blackjee-foundation.zip`; blob IDs match the archive byte-for-byte.
- Two applied bodies remain missing: `20261024081337_numeric_answers_and_admin_review` (archive has a different-version near-match only) and `20261024112132_require_pyq_source_page_before_publish`.
- Clean original-chain replay remains blocked. Do not run `supabase db reset`, `migration repair`, or ad hoc DDL against the target.
- Continue source recovery from archives/history and compare recovered bodies to live catalog evidence. Any inferred baseline must be separately labelled; no production ledger or schema mutation is authorized.

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
