# Test plan

## Test status — refreshed 2026-10-25

The latest verified fully green CI run is [40196563553](https://github.com/black-jee/blackjee/actions/runs/40196563553) (run #618): `quality` and `reconstruction-replay` passed. Quality includes dependency audit, lint, typecheck, unit tests, Playwright E2E, formatting, and application build. The disposable PostgreSQL replay also runs synthetic authorization/input-integrity regression cases. These synthetic compatibility-auth checks are not equivalent to real Supabase Auth or Supabase-issued JWT validation.

Read-only checks against the configured target Supabase project previously exercised the public schedule RPC, restricted anonymous column grants, private-table browser-role privileges, admin challenge-save RPC, and mock-test ownership/private-response privileges. Mock-test start/resume/submit were exercised against an empty bank and correctly rejected unavailable attempts. Authenticated student/admin browser workflows and database-backed seeded question workflows remain unverified. Do not treat old CI notes below as current pipeline status.

## Real Supabase Auth/JWT validation gate

Do this only in an owner-approved staging Supabase project with disposable test accounts and synthetic records; never use production student data or real JEE content for security fixtures. Required prerequisites: a dedicated staging project or explicitly approved isolated test environment, test-only student A/student B/admin accounts, supported way to obtain genuine Supabase-issued access tokens, and a cleanup plan limited to test-owned fixtures. Never paste service-role keys or user tokens into repository files, logs, CI output, or chat.

1. Obtain real access tokens through the normal Supabase Auth sign-in flow for each test identity.
2. With anonymous access, assert admin RPCs are denied and private answer/session/response tables cannot be queried.
3. With student A, assert own permitted challenge/mock-test operations work and student B's session, responses, results, and attempts remain inaccessible and unmodifiable.
4. Repeat spoofed-admin checks with `user_metadata.role=admin`; assert it grants no administrative privileges. Separately verify the actual approved admin claim path using a dedicated admin account.
5. Check answer-key/solution withholding before the release boundary and ownership checks on every result/read/write path.
6. Record sanitized pass/fail outcomes and cleanup evidence; do not log JWTs, secrets, answer keys, or personal data.

Until this gate runs successfully, mark real Supabase JWT parity and authenticated student/admin workflows **not verified**. Do not create a paid project/branch or modify production to perform these tests.

## Automated gates

1. **Format/lint:** reject inconsistent formatting and lint errors.
2. **Type check:** strict TypeScript compilation.
3. **Unit (Vitest):** schemas, question normalization, timer boundary calculations, release-window logic, option parsing and safe rendering helpers.
4. **Database integration:** run against a dedicated test/staging project; use transactions or isolated fixtures and clean up only test-owned data.
5. **E2E (Playwright):** actual app in browser; anonymous, student and admin workflows; desktop and mobile viewports.
6. **Production build:** required before merge/deploy.
7. **Security/performance:** Supabase advisors, dependency audit and secret scanning.

## Required scenarios

- Login/logout, invalid credentials, expired session and protected route redirects.
- Admin route and API denial for anonymous users and ordinary students.
- Student-specific data isolation (Student A cannot read or mutate Student B records).
- Challenge schedule/open/close boundary and server-side one-attempt enforcement.
- Timer tampering and duplicate/parallel submission attempts.
- Correct/incorrect grading, answer-key withholding and delayed solution release.
- Optional photo upload, size/type rejection, private storage and signed URL expiry.
- PYQ import validation, source ID uniqueness, draft invisibility, review and publish.
- Question statement, options, image options, diagrams, chemistry notation and KaTeX formulas.
- Chapter filters, pagination, navigation, mock-test timer and results.
- Mock-test exact 75-question shift validation, attempt ownership, resume isolation, late submission rejection, answer-key non-disclosure before submission, marking and result ownership.
- Admin create/edit/preview/schedule/publish, review queue, CSV export and safe destructive confirmation.
- Crop/image mapping and manifest checks; missing asset fallback.
- Accessibility basics: keyboard operation, focus visibility, labels, contrast and reduced-motion behavior.
- Recovery from API errors, offline/network interruption, empty datasets and stale sessions.

## Historical CI observation

CI run `40088044408` passed the complete pipeline: `npm ci`, ESLint, strict TypeScript, Vitest, Playwright E2E smoke tests, Prettier check, and Next.js production build. The lockfile is committed and CI uses `npm ci`. The new admin PYQ UI and server actions still require authenticated end-to-end tests.

## Content verification

For each imported question, verify source wording, options, correct answer, solution, subject/chapter metadata, all asset references, alt text and mobile rendering. Structural manifest checks cannot prove factual accuracy. The April 4 Shift 1 unresolved items stay blocked until an authoritative source image/PDF is available and checked.

## Release criteria

No unresolved critical authorization, data integrity or answer-key exposure issue. All required core student/admin E2E flows pass in staging. Production build and type/lint gates pass. Backups/restore and rollback steps are documented. Production cutover remains subject to owner approval.
