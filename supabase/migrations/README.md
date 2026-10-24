# Supabase migration discipline

The target Supabase project already had six applied migrations before the new GitHub repository was scaffolded. Their names and versions are visible in Supabase migration history, but their original SQL files were not present in the new repository.

Known applied baseline versions:

- `20261024080824_foundation_schema`
- `20261024080924_tighten_rpc_grants_and_policy`
- `20261024081041_daily_solution_release_rpc`
- `20261024081337_numeric_answers_and_admin_review`
- `20261024081603_secure_daily_attempt_sessions`
- `20261024081731_restrict_anon_rpc_execution`

The repository-managed migrations added so far are:

- `20261024095050_harden_public_schedule_rpc_and_index.sql`
- `20261024100007_daily_challenge_question_assets.sql`
- `20261024100245_pyq_question_image_paths.sql`
- `20261024100341_question_image_path_read_grants.sql`
- `20261024100524_admin_save_daily_challenge.sql`

## Important current limitation

**Do not run `supabase db reset` against this incomplete local migration directory.** The original six SQL bodies need to be reconstructed from the live schema and reviewed before this repo can be used to recreate a clean database from zero. The live target project is currently intact; this documentation does not pretend that the missing migration files have been recovered.

## Required reconciliation procedure

1. Export/inspect current table definitions, constraints, indexes, policies, grants, functions and storage state from the target project.
2. Reconstruct a clean, ordered baseline migration chain that reproduces the current schema on an empty staging database.
3. Compare the recreated schema against the live target and verify all six existing migration versions.
4. Keep future changes in versioned SQL files, apply to staging first, and run SQL negative-permission tests plus Supabase advisors.
5. Never edit or re-run an already-applied migration against the live project; use a new additive migration for changes.
