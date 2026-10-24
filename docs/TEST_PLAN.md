# Test plan

## Test status

No application test is marked passing until it is actually executed against the current implementation. The new SQL regression assertions for the public schedule RPC and restricted anonymous column grants have been run successfully against the target Supabase project. The legacy ZIP contains static security checks, inline-JS checks, question-manifest audits, a crop processor and a SQL regression test; these are useful references but do not constitute end-to-end coverage for the new application.

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
- Admin create/edit/preview/schedule/publish, review queue, CSV export and safe destructive confirmation.
- Crop/image mapping and manifest checks; missing asset fallback.
- Accessibility basics: keyboard operation, focus visibility, labels, contrast and reduced-motion behavior.
- Recovery from API errors, offline/network interruption, empty datasets and stale sessions.

## Content verification

For each imported question, verify source wording, options, correct answer, solution, subject/chapter metadata, all asset references, alt text and mobile rendering. Structural manifest checks cannot prove factual accuracy. The April 4 Shift 1 unresolved items stay blocked until an authoritative source image/PDF is available and checked.

## Release criteria

No unresolved critical authorization, data integrity or answer-key exposure issue. All required core student/admin E2E flows pass in staging. Production build and type/lint gates pass. Backups/restore and rollback steps are documented. Production cutover remains subject to owner approval.
