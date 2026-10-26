# Real Supabase Auth integration test plan

**Status:** HARNESS ADDED; execution BLOCKED pending isolated test credentials/fixtures.  
**Scope:** isolated, disposable test environment only. This plan is not evidence that production authorization has been verified.

## Entry conditions

- Use a dedicated Supabase test project or disposable local Supabase stack with no production data.
- Never use the production project ref `phdssyexhfyxsmhmmcgb` for test writes.
- Configure test-only URL and publishable key as ordinary test secrets. Do not place a service-role/secret key in browser variables, logs, fixtures, or screenshots.
- Create two ordinary test users (A and B) and one admin test user using the documented server-managed `app_metadata.role = admin` claim. Do not grant admin by editing user-controlled `user_metadata`.
- Seed only synthetic mock-test, daily-challenge, and PYQ draft records. Use deterministic IDs and cleanup in the disposable environment.
- If test credentials or an isolated Supabase environment are unavailable, leave these tests blocked; do not substitute simulated SQL claims and call them real-auth tests.

## Test matrix

| ID       | Actor / setup                                  | Operation                                           | Required result                                                                                                                         |
| -------- | ---------------------------------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| AUTH-01  | No session                                     | Invoke each exposed RPC                             | Denied; no private answer or attempt data returned                                                                                      |
| AUTH-02  | User A owns attempt A; user B owns attempt B   | User A requests B's mock-test result                | No B data returned; denial/error matches the documented API contract                                                                    |
| AUTH-03  | User A owns attempt A; user B owns attempt B   | A resumes B's attempt                               | Denied; B's attempt remains unchanged                                                                                                   |
| AUTH-04  | User A owns attempt A; user B owns attempt B   | A submits against B's attempt ID                    | Denied; no response or score mutation for B                                                                                             |
| AUTH-05  | User A owns attempt A; user B owns attempt B   | A submits question IDs not belonging to A's attempt | Rejected; no partial mutation                                                                                                           |
| AUTH-06  | Ordinary authenticated user                    | Call each admin save/review RPC                     | Denied; no draft mutation                                                                                                               |
| AUTH-07  | Dedicated admin                                | Save and review a synthetic PYQ as draft            | Allowed only for valid synthetic data; remains unpublished                                                                              |
| REL-01   | Before solution release time                   | Fetch daily challenge result                        | No correct answer or solution in response                                                                                               |
| REL-02   | At and after release boundary                  | Fetch daily challenge result                        | Verify exact documented release semantics and absence of early leakage                                                                  |
| REL-03   | Authenticated user without a challenge session | Request a released challenge result                 | Record actual behavior; confirm whether post-release learning is intentionally public to all authenticated users before changing policy |
| PYQ-01   | Anonymous and ordinary student                 | Read a draft PYQ through public-facing paths        | Draft answer/solution and unpublished content remain inaccessible                                                                       |
| PYQ-02   | Admin with incomplete synthetic draft          | Attempt publish                                     | Rejected unless all source provenance, source page, statement, options, answer key, and solution requirements are satisfied             |
| CLEAN-01 | All test actors                                | End run                                             | Remove only synthetic fixtures in the disposable environment; never run cleanup against production                                      |

## Execution approach

1. Use the official Supabase client with a real password/OTP sign-in flow to obtain signed access tokens for A, B, and admin.
2. Call the RPCs through the normal authenticated client using each user's own token. Do not manually set `request.jwt.claims` or forge JWTs.
3. Capture only test IDs, operation, status/error code, and pass/fail. Never log access/refresh tokens or secret keys.
4. Assert both the response and persisted state after every denied mutation.
5. Run the matrix in CI only when a dedicated isolated test project and its credentials are configured as protected test secrets. Keep the normal no-secret CI path deterministic.
6. Save the run URL and commit SHA in `docs/VERIFICATION_LOG.md`; distinguish real-token integration results from disposable PostgreSQL tests that simulate JWT claims.

## Acceptance criteria

- Every AUTH and PYQ denial case passes under a real signed user token or anonymous client as applicable.
- Cross-user negative operations leave the victim's attempt/session/results unchanged.
- Release tests establish the intended before/at/after boundary without exposing answers early.
- Admin-positive cases use a server-managed admin claim and synthetic drafts only.
- No production writes, production credentials, real question content, or paid resources are used.

## Known product-policy question

The read-only review of `get_daily_challenge_result` indicates that any authenticated caller who knows a challenge ID may receive its answer/solution after `solution_release_at`, without proving prior participation. This could be intentional post-release learning behavior. Do not change it until the product rule is confirmed; keep REL-03 as an explicit decision.

## Repository test harness added — 2026-10-26

The optional Vitest suite `tests/real-supabase-auth.integration.test.ts` now signs in three pre-provisioned synthetic users through the official Supabase client and checks anonymous RPC denial, student-to-student mock-attempt isolation, ordinary-student admin denial, pre-release solution withholding, and direct private-schema denial. It is automatically skipped unless every variable below is configured. A skipped test is not a pass.

Required protected test-only environment variables:

- `BLACKJEE_AUTH_TEST_URL`
- `BLACKJEE_AUTH_TEST_PUBLISHABLE_KEY`
- `BLACKJEE_AUTH_TEST_STUDENT_A_EMAIL`, `BLACKJEE_AUTH_TEST_STUDENT_A_PASSWORD`
- `BLACKJEE_AUTH_TEST_STUDENT_B_EMAIL`, `BLACKJEE_AUTH_TEST_STUDENT_B_PASSWORD`
- `BLACKJEE_AUTH_TEST_ADMIN_EMAIL`, `BLACKJEE_AUTH_TEST_ADMIN_PASSWORD`
- `BLACKJEE_AUTH_TEST_B_IN_PROGRESS_ATTEMPT_ID`
- `BLACKJEE_AUTH_TEST_B_SUBMITTED_ATTEMPT_ID`
- `BLACKJEE_AUTH_TEST_UNRELEASED_CHALLENGE_ID`

The three accounts and fixture IDs must belong to the same disposable Supabase environment, seeded with synthetic data. The admin account must already have server-managed `app_metadata.role = 'admin'`; the suite asserts this claim after signing in. Do not provide a service-role/secret key to this test.

Current connector inventory exposes only the existing production project `phdssyexhfyxsmhmmcgb`. It must not be used for test writes. No separate test project or local Supabase Auth stack has been provisioned, and no real signed-token tests have yet run. Do not configure the variables until an isolated disposable environment and cleanup procedure are available.
