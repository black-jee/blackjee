# BLACK-JEE continuity system prompt

This file is the startup contract for any AI assistant or engineer resuming BLACK-JEE. The repository is the permanent source of truth; chat history and model memory are supplementary.

## Active project identity

- New repository: https://github.com/black-jee/blackjee
- Active branch: `main`
- Target Supabase project ref: `phdssyexhfyxsmhmmcgb`
- Owner-supplied website: https://blackjee.vercel.app/
- Legacy repository/site are reference-only: https://github.com/bhavishyacodz/BLACK-JEE and https://bhavishyacodz.github.io/BLACK-JEE/
- Never modify the legacy system or switch production targets unless the owner explicitly authorizes it.

## Mandatory startup sequence

1. Read this file, `docs/PROJECT_CONTEXT.md`, `docs/PROJECT_STATUS.md`, and `docs/SESSION_HANDOVER.md`.
2. Read the current task entry in `docs/TASKS.md`; inspect relevant architecture, database, security, and test documents.
3. Inspect the actual `main` tree, latest commit, recent changes, workflow results, and current task-specific code. Treat handover as evidence to reconcile, not unquestionable truth.
4. Search the task ledger for an existing task before adding one. Reopen/update an existing task when the purpose matches.
5. Resume the same unfinished task unless it is complete and verified, a critical issue supersedes it, a dependency blocks it, the owner changes priorities, or new evidence invalidates it.
6. Preserve unrelated work and owner changes. Do not reset, overwrite, or destructively migrate production data. Risky database changes require backup, impact assessment, isolated replay, and owner approval.
7. Make authorized changes directly when connected access permits. Never claim access, tests, commits, deployments, or verification without returned evidence.
8. After each meaningful unit, update `TASKS.md`, `VERIFICATION_LOG.md`, `PROJECT_STATUS.md`, and this handover. Update any affected technical docs.
9. Keep secrets, tokens, service-role keys, and personal student data out of repository documentation and logs.

## Required task and verification discipline

Task states: `DISCOVERED`, `PLANNED`, `IN_PROGRESS`, `BLOCKED`, `IMPLEMENTED`, `TESTED`, `DEPLOYED`, `PRODUCTION_VERIFIED`. Use `TESTED` only with concrete test evidence; `DEPLOYED` and `PRODUCTION_VERIFIED` are separate states.

Verification outcomes must be labelled `PASS`, `FAIL`, `SKIPPED`, or `UNVERIFIED`, and identify the commit/environment, exact check, result, and limitations. Do not turn a skipped build or an inaccessible production URL into a pass.

## Mandatory end-of-session sequence

1. Record the task progress and evidence.
2. Update verification log and project status.
3. Write the exact next action and next checks into `SESSION_HANDOVER.md`.
4. Record any new decision and update technical documentation as needed.
5. Confirm the commit SHA returned by GitHub before reporting a commit. Report any checks still running or failing.
6. Do not perform a production switch, destructive database operation, or question publication without the required approvals and QA.

## Fast resume command

When the owner says **RESUME BLACK-JEE** or **Continue**, follow the startup sequence and proceed with the exact next action in `SESSION_HANDOVER.md`; do not ask the owner to repeat already documented project setup.
