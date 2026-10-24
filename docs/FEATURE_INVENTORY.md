# BLACK-JEE feature inventory

**Source inspected:** uploaded `BLACK-JEE-main.zip` (84 files; 17 HTML pages; 19 SQL files; 21 PNG/JPG images).  
**Reference system:** `bhavishyacodz/BLACK-JEE` and its GitHub Pages URL.  
**Status legend:** Not started · In progress · Implemented · Tested · Verified · Blocked.  
**Rule:** source presence is not proof of runtime correctness. No feature below is marked Verified yet.

## Student application

| Feature / workflow | Source files | Expected behavior / dependencies | Migration status | Verification method |
|---|---|---|---|---|
| Home dashboard and daily challenge entry | `index.html`, `attempt.html`, `rules.html` | Show schedule metadata; reveal question only through trusted start flow; respect opening/closing times | Implemented — initial `/challenge` route and server actions; runtime verification pending | Playwright anonymous and signed-in flows; RPC/database tests |
| Challenge attempt, timer, answer submission | `attempt.html`, source SQL/migrations | Start session server-side, enforce one attempt, calculate elapsed time, submit once | Not started | Unit/integration tests for timing, duplicate submission and boundaries |
| Challenge history/results | `archive.html`, `profile.html` | Student-specific history; result and solution release at configured time | Not started | Cross-user access tests and release-window tests |
| Optional solution photo | `attempt.html`, Supabase storage policies and Edge Function source | Private upload, validated file type/size, owner/admin-only access until approved | Not started | Upload limits, storage RLS and signed URL tests |
| Student profile / authentication | `profile.html`, all auth-dependent pages | Supabase Auth, secure session, user-owned records | In progress — email/Google sign-in, OAuth callback, password reset/update, profile/history and sign-out routes; runtime verification pending | Sign-in/out, session expiry and IDOR tests |
| Preparation/resources | `prep.html` | Resources and practice entry points | Not started | Link, responsive and accessibility tests |

## PYQ, practice and mock tests

| Feature | Source files / assets | Expected behavior | Migration status | Verification method |
|---|---|---|---|---|
| PYQ browse/search/filter | `pyq.html`, question manifests | Browse approved questions; filter by exam/year/subject/chapter; paginate | In progress — initial `/pyq` published-question browse, subject/text filters, authenticated grading and two-wrong-answer solution gate; runtime verification pending | Query tests and browser filtering tests |
| Chapter-wise navigation | `chapterwise.html` | Subject → chapter/topic → questions | Not started | Navigation and empty-state tests |
| Chapter practice / grading | `chapter-practice.html`, source SQL migrations | Answer, grade on server, protect answer keys/solutions, per-user attempt rules | Not started | Anonymous/authenticated and cross-user SQL tests |
| Mock tests / CBT | `mock-tests.html` | Timed question navigation, answer selection, submission/results where present | Not started | Timer, navigation, persistence and mobile tests |
| Question bank import/review | `pyq-admin.html`, manifests, audit scripts | Import to draft, validate data and assets, review before publication | Not started | Zod/CSV validation and import fixtures |
| April 4 2026 Shift 1 content | `assets/questions/jee-main-2026-apr-4-shift-1/` | 75 tracking slots; exact question/source/answer/solution/asset reconciliation | Blocked for publication | Source crosswalk, batch audit, manual paper comparison, rendered tests |

## Admin and content production

| Feature | Source files | Expected behavior | Migration status | Verification method |
|---|---|---|---|---|
| Owner dashboard | `owner-dashboard.html` | Admin entry point and overview | Not started | Role-denial and admin smoke tests |
| Daily challenge admin | `admin.html`, `attempt.html?admin=1` | Create/edit/preview/schedule/publish; moderate submissions; export and cleanup | In progress — protected admin route, create/schedule form and database-guarded save RPC; edit, moderation, export and cleanup pending | Full admin CRUD workflow and audit-log checks |
| PYQ administration | `pyq-admin.html` | Search, import, draft/review/publish | Not started | Draft isolation and authorization tests |
| Shift workbench | `shift-workbench.html` | Track paper slots and review states | Not started | Manifest count/order assertions |
| Diagram audit and crop review | `diagram-audit.html`, `draft-image-review.html`, `image-crop-studio.html` | Crop, associate, inspect and verify images without auto-publishing | Not started | Image association, crop processor and UI tests |
| Bulk cleanup / CSV export | `admin.html`, `supabase/functions/admin-cleanup/index.ts` | Explicit confirmation, export-before-delete, remove associated private assets | Not started | Admin-only tests and storage cleanup checks |

## Backend contracts discovered by source scan

The legacy browser code references these RPCs: `get_challenge_archive`, `admin_get_live_question`, `start_challenge_attempt`, `restore_submitted_challenge_attempt`, `submit_challenge_answer`, and `grade_jee_pyq`. It references the legacy tables `daily_questions`, `active_question_links`, `attempt_submissions`, and `jee_pyq_questions`, plus private answer-key access in admin workflows. The new project currently has different daily-challenge RPC names: `get_current_daily_challenge`, `get_daily_challenge_result`, `start_daily_challenge`, and `submit_daily_challenge`; its PYQ grading RPC is `grade_jee_pyq`.

**Migration requirement:** create a documented source-to-target contract map and either migrate the client callers to the target RPCs or add compatible server APIs. Do not assume similarly named functions have the same return shape or authorization behavior.

## Engineering / integrations

| Area | Source files | Status / notes |
|---|---|---|
| Existing schema and migrations | `supabase/schema.sql`, `supabase/migrations/*.sql` | Inspected. Original uses `daily_questions`/attempt submissions; new Supabase currently uses `daily_challenges`/attempts. Requires explicit mapping, not blind replay. |
| Edge Functions | `supabase/functions/admin-cleanup/index.ts`, `supabase/functions/released-solution/index.ts` | Source exists; neither function is currently deployed in the new Supabase project. |
| Math rendering | KaTeX on `attempt.html`; MathJax on admin/PYQ tooling | Consolidate to one shared KaTeX renderer and test equations, chemistry notation and fallback behavior. |
| Question image assets | `assets/questions/**/images`, `assets/gemini-inbox/**` | Archive includes images and manifests; some source questions are explicitly unresolved. |
| CI and audits | `.github/workflows/*.yml`, `scripts/*.py` | Reuse/port relevant audits into the new CI; expand beyond static checks. |
| PWA/cache | `sw.js` | Inspect cache invalidation implications before porting. |

## Confirmed content gaps / blockers

- The April 4 Shift 1 README says the 75-slot tracking manifest is not a complete verified question set. It flags Mathematics Q19, Physics Q38, Chemistry Q64, and Chemistry Q72 as unresolved, and says the package is not diagram-complete.
- The source ZIP does not provide old database rows, auth users, production uploads, secret values, or authoritative original question-paper PDF. These cannot be recovered by code migration alone.
- The original README points to a different Supabase project. That old project is reference-only and must not be connected to or modified.
- The original live page content could not be retrieved during the first live-site comparison attempt. A real-browser comparison remains outstanding.

## Definition of done

A row moves to **Verified** only after its prescribed automated/runtime checks have run and passed. Any missing source, external service, account configuration or unresolved content must remain explicitly Blocked until supplied or resolved.
