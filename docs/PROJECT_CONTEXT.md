# BLACK-JEE project context

**Last reconciled:** 2026-10-24  
**Status:** In progress; not production-ready.

## Mission
Build a reliable, secure, mobile-first JEE Main and JEE Advanced preparation platform. Educational correctness, student privacy, answer-key confidentiality, accessibility, and traceable verification take precedence over cosmetic polish.

## Active targets
- **Repository:** https://github.com/black-jee/blackjee (default branch `main`).
- **Supabase:** project ref `phdssyexhfyxsmhmmcgb` (observed ACTIVE_HEALTHY; PostgreSQL 17.11, Tokyo region).
- **Production URL supplied by owner:** https://blackjee.vercel.app/. The current deployment's commit, Vercel project linkage, environment variables, and production runtime have not been independently verified in this session.
- **Legacy reference only:** https://github.com/bhavishyacodz/BLACK-JEE and https://bhavishyacodz.github.io/BLACK-JEE/. Do not modify these as part of new-system work unless explicitly requested.

## Architecture currently present
Next.js App Router, React, strict TypeScript, Tailwind CSS, Supabase Auth/Postgres, server actions, Zod validation, KaTeX, Vitest, Playwright, and GitHub Actions. Verify individual routes and flows before calling them complete.

## Stable constraints
- Never publish question content without authoritative source provenance, source page, a private answer key, a worked solution, and review.
- Never expose private answer keys or unreleased challenge content to browser roles.
- Never reset or destructively migrate the target Supabase project without a backup, impact assessment, isolated replay test, and owner approval.
- Never deploy a breaking change or switch production without explicit authorization.
- Keep the legacy project and new project clearly separated.
- Use server-managed `app_metadata.role = admin` for admin authorization; user-editable metadata is not trusted.
- Distinguish implemented, tested, deployed, and production-verified states.

## Evidence and unknowns
- The target Supabase currently has five PYQ records and zero published PYQs; all five are unpublished drafts.
- Migration history contains 20 applied versions, while the checked-in migration directory has 15 SQL migration files. Six original baseline SQL bodies remain unreconstructed; never run a reset against this incomplete chain.
- The source archive's April 4 Shift 1 package describes 75 question slots; the official source PDF is not present in that archive. No bulk import or publication is authorized by this evidence.
- Latest older successful CI run: run 40090330071, commit `57d04ed9d3db332e0aafe71d69423be5723c7ff5`. The run for HEAD `ec2f7ce1bfb25a0b1e96f3168ab82959c8a5af1e` failed Prettier format check; the production build was skipped. See `docs/VERIFICATION_LOG.md`.
- Authenticated student/admin browser journeys and Vercel production behavior remain unverified.

## Product priorities
P0 security/data loss/answer leakage; P1 critical student flows, scoring, auth and deployments; P2 missing workflows, integrity, admin, accessibility and performance; P3 usability/content improvements; P4 experiments. See `docs/TASKS.md` for the authoritative task ledger.
