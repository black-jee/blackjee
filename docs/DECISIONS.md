# BLACK-JEE engineering decisions

## D-001 — Keep the new platform separate from legacy production
- **Date:** 2026-10-24
- **Decision:** Treat `black-jee/blackjee` and Supabase project `phdssyexhfyxsmhmmcgb` as the new implementation target; treat the original repository and GitHub Pages site as legacy reference only.
- **Reason:** Avoid accidental writes to the wrong repository/database.
- **Consequence:** Verify project refs before each write and do not switch production without owner approval.

## D-002 — Keep PYQs unpublished until provenance and solution are complete
- **Date:** 2026-10-24
- **Decision:** Publishing requires a source document, source page, non-empty statement, private answer key, worked solution, and a valid option label for single-correct questions.
- **Reason:** Protect educational accuracy and prevent unsupported content from reaching students.
- **Evidence:** Live database function definition includes these checks; five PYQ records are still drafts.
- **Consequence:** Missing source PDF and unresolved manifest items remain blockers; no bulk publish.

## D-003 — Do not reset Supabase while migration baseline is incomplete
- **Date:** 2026-10-24
- **Decision:** No reset or destructive migration on the target project until the six missing original migration bodies are reconstructed and replayed on isolated staging.
- **Reason:** Live migration history cannot currently be reproduced from the repository alone.
- **Consequence:** Additive migrations only on the active project, with schema comparison and backup/approval for risky changes.

## D-004 — Separate implementation status from verification status
- **Date:** 2026-10-24
- **Decision:** Use the constitution's eight task states and require direct evidence for test, deployment, and production claims.
- **Reason:** Source presence and a green CI run do not prove production behavior.
- **Consequence:** Track authenticated browser tests and Vercel verification separately.
