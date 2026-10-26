# Cloudflare Pages Static Export Migration

## Goal

Deploy BLACK-JEE on Cloudflare Pages as a static Next.js export (`out/`). Do not switch the project to Workers or restore unvalidated UI changes from another branch.

## Verified baseline

- The current `main` build completes with Next.js 16, but Cloudflare Pages fails because its configured output directory is `out` and the build does not produce that directory.
- `next.config.ts` currently has no `output: "export"`.
- `proxy.ts` refreshes Supabase auth cookies and therefore cannot continue as Next.js request middleware in a pure static export.
- `app/auth/callback/route.ts` is a server Route Handler.
- Server Actions exist in `app/admin/actions.ts`, `app/admin/pyq/actions.ts`, `app/challenge/actions.ts`, `app/mock-tests/actions.ts`, and `app/pyq/actions.ts`.
- Database-backed server rendering exists on challenge, chapter practice, chapterwise, mock-test, profile, admin, and PYQ routes. Some routes explicitly use `dynamic = "force-dynamic"`.
- Existing Supabase SQL migrations and security tests are present. Preserve their authorization guarantees during the migration; never replace server-side authorization with UI-only checks.

## Migration sequence

1. **Map server-only dependencies.** For every route and component, classify server data reads, Server Actions, route handlers, cookie/session assumptions, and dynamic rendering. Identify which data can safely be queried from the browser under existing RLS and which must remain behind a trusted server endpoint.
2. **Choose the backend boundary.** Static Pages cannot run Next.js Server Actions or server Route Handlers. Move operations that require trusted execution to Supabase RPCs/Edge Functions with explicit authorization, or redesign them as direct browser calls to existing RPCs only after verifying their database-side authorization. Never expose a service-role key.
3. **Migrate authentication.** Replace cookie-refresh middleware and the server OAuth callback with a browser-compatible Supabase auth flow. Verify PKCE callback handling, sign-in/sign-out, password reset, and session restoration on direct page loads.
4. **Migrate route data loading.** Convert server-rendered queries to client-side loading states and explicit error/empty states. Protect private data through database RLS/RPC authorization rather than route visibility.
5. **Enable export last.** Add `output: "export"` only after incompatible server features are removed or replaced. Ensure every route can be generated at build time; handle dynamic paths with static route generation or client-side routing.
6. **Verify locally and in CI.** Run format, lint, typecheck, unit tests, production build, and Playwright smoke tests. Confirm `out/` exists and contains home, login, callback/reset pages, and every supported route. Test logged-out, logged-in, and admin flows, plus direct navigation/refresh on nested URLs.
7. **Deploy and verify.** Configure Pages with `npx next build` and output directory `out`; validate the deployed URL and browser console before declaring the migration complete.

## Acceptance criteria

- `npm run build` succeeds and creates `out/`.
- No unsupported Server Actions, dynamic server rendering, middleware/proxy, or Route Handlers remain in the static-export route graph.
- No Supabase service-role or other privileged secret is bundled into client assets.
- Existing SQL security tests still pass, and authorization tests cover any new RPC/Edge Function boundary.
- Playwright smoke tests cover navigation, authentication callback, PYQ practice, challenge/mock-test start and submission, and admin denial for non-admin users.
- Cloudflare Pages deploy succeeds and deep links work on refresh.

## Current status

This document records the verified blockers and safe migration order. It does not claim that the application has been migrated, built as a static export, or deployed successfully. The configuration change must remain the final step, not a speculative one-line fix.
