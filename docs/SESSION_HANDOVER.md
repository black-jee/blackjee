# BLACK-JEE session handover

**Updated:** 2026-10-24  
**Active task:** BJ-DB-001 — recover and reconcile missing applied migration SQL without paid infrastructure  
**Branch:** `main`  
**Repository:** https://github.com/black-jee/blackjee  
**Supabase target:** `phdssyexhfyxsmhmmcgb`  
**Production URL supplied by owner:** https://blackjee.vercel.app/ (deployment linkage and runtime not verified)

## Latest verified state

- Observed `main` HEAD: [`ffc1437b`](https://github.com/black-jee/blackjee/commit/ffc1437b1381bb000c6a1417210e9891182509a0) — `docs: fix migration recovery command formatting`.
- CI run [40101661444](https://github.com/black-jee/blackjee/actions/runs/40101661444) passed on this HEAD. Configured quality gates include continuity validation, dependency install, lint, typecheck, unit tests, Playwright E2E, Prettier, and production build.
- GitHub Pages workflow [40101661202](https://github.com/black-jee/blackjee/actions/runs/40101661202) passed on this HEAD. This does **not** verify the owner-supplied Vercel deployment.
- Supabase migration history contains 20 applied versions. Seven applied SQL bodies are missing from the repository: six baseline bodies and `20261024112132_require_pyq_source_page_before_publish`.
- Repository has 15 migration files; `20261024112500` and `20261024120000` are not recorded as applied in the live history. Do not treat either as the missing `20261024112132` original.
- Searches of the checked public repository history and indexed code search did not recover the missing originals. The search does not cover the owner's local device, private repos, other clones, or unuploaded backups.
- The owner's budget constraint is explicit: **do not create a Supabase branch/project or incur infrastructure charges**.
- No production DDL, migration apply/repair, reset, row mutation, question publication, or paid infrastructure creation was performed during this work.

## Current work and blockers

### BJ-DB-001 — migration recovery and replay

- Inventory and recovery evidence: `docs/MIGRATION_RECONCILIATION.md`, `docs/MIGRATION_CHAIN_INVENTORY.md`, and `docs/MIGRATION_RECOVERY_SEARCH_2026-10-24.md`.
- Current state: historical SQL recovery remains blocked; clean replay remains unverified. Do not run `supabase db reset`, `migration repair`, or ad hoc DDL against the target.
- Next: continue no-cost recovery from owner-controlled Termux folders, archives, older clones, backups, or other trustworthy artifacts. If originals cannot be recovered, create a separately labelled reconstructed baseline and review it as reconstruction—not original history. Only test in a disposable PostgreSQL service in GitHub Actions with no production credentials, after a replayable chain has been assembled.

### Security and authenticated journeys

- `docs/SECURITY_DEFINER_REVIEW_2026-10-24.md` records read-only function/grant inspection and remaining security tests.
- Authenticated cross-user isolation, admin denial for ordinary users, and daily-solution/PYQ release boundaries still need runtime tests in an isolated setup. Do not create or publish real content for testing.
- Current security advisor findings include private tables with RLS enabled but no policies and warnings about authenticated execution of SECURITY DEFINER functions. These are findings to assess against the intended mediated-access design, not automatic proof of a vulnerability. Do not change grants/policies without a reviewed test plan.

### Content and deployment

- Five PYQs are drafts and zero are published. The official April 4 Shift 1 source PDF is missing; keep unresolved content unpublished.
- Vercel project linkage, active deployed commit, environment-variable presence, and production smoke behavior remain unverified. Never print secret values.
- The source archive lists 75 question slots (47 marked content_added, 28 needs_review); reconcile each against an authoritative source before import or publication.

## Safe operating rules

1. Treat live Supabase checks as read-only until a separately reviewed change is explicitly approved.
2. Never expose service-role keys, passwords, or environment-variable values in logs or client-side variables.
3. Never fabricate missing migration SQL or question content.
4. Use free, isolated test environments only; the owner cannot afford a paid Supabase branch.
5. Update this handover and `docs/TASKS.md` when verified evidence changes.
