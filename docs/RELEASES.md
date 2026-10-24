# BLACK-JEE release register

## Current release state

- **Release status:** No production release is verified by this register.
- **Production URL supplied by owner:** https://blackjee.vercel.app/
- **Repository:** https://github.com/black-jee/blackjee, branch `main`.
- **Latest successful older CI evidence:** run [40090330071](https://github.com/black-jee/blackjee/actions/runs/40090330071), commit `57d04ed9d3db332e0aafe71d69423be5723c7ff5`. This does not establish current HEAD as green.
- **Current continuity CI:** run [40091156887](https://github.com/black-jee/blackjee/actions/runs/40091156887) failed at Prettier format check; lint, typecheck, unit tests, E2E, and continuity validator passed; build was skipped.
- **Supabase:** project `phdssyexhfyxsmhmmcgb`; 20 migration versions recorded. Clean replay remains blocked by six missing baseline migration bodies.

## Release history

| Date       | Identifier                                 | Change                                                 | Verification                        | Deployment                                          |
| ---------- | ------------------------------------------ | ------------------------------------------------------ | ----------------------------------- | --------------------------------------------------- |
| 2026-10-24 | `57d04ed9d3db332e0aafe71d69423be5723c7ff5` | Source-page PYQ publish-gate test/documentation update | GitHub CI run 40090330071 succeeded | Not established; do not infer production deployment |

## Release gates

1. CI lint, typecheck, unit tests, E2E smoke, formatting and production build pass.
2. Migration reviewed and tested on isolated staging; backup/rollback plan exists for schema changes.
3. Security-negative tests pass for anonymous, student, and admin boundaries.
4. Content QA and provenance complete; no unsupported question/answer is published.
5. Preview deployment smoke test passes; owner approves production deployment.
6. After deploy, record deployed commit and production smoke evidence.

## Rollback principles

- Prefer reverting application code to a known-good commit if compatible with the current schema.
- Do not blindly roll back applied database migrations; write a forward corrective migration unless a reviewed rollback is safe.
- Preserve student attempts and historical challenge records.
- Never run a production reset as a rollback strategy.
