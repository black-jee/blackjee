# Cloudflare Workers Migration

## Goal

Run BLACK-JEE as a full-stack Next.js application on Cloudflare Workers. Keep Next.js server rendering, Server Actions, Route Handlers, and Supabase authentication working where needed. Do not enable `output: "export"` or target the Cloudflare Pages static `out/` directory.

## Deployment approach

Cloudflare's current Next.js guidance recommends vinext for new Worker deployments and offers a non-destructive initializer for existing Next.js 16 projects. The OpenNext Cloudflare adapter is a more established compatibility path for existing Next.js applications and supports App Router, Route Handlers, SSR, Server Actions, and middleware. Before selecting the final adapter, run the official compatibility checks and build/test the actual BLACK-JEE routes. Do not switch framework adapters blindly.

Official references:
- Cloudflare Next.js on Workers: https://developers.cloudflare.com/workers/framework-guides/web-apps/nextjs/
- Cloudflare OpenNext adapter: https://developers.cloudflare.com/workers/framework-guides/web-apps/opennext/
- OpenNext migration guide: https://opennext.js.org/cloudflare/get-started

## Current repository state

- The app uses Next.js 16 and Supabase.
- Server Actions exist in admin, daily challenge, mock-test, and PYQ code.
- `app/auth/callback/route.ts` was replaced on this branch with a browser-side OAuth callback page; verify PKCE exchange and session restoration end-to-end.
- `proxy.ts` refreshes Supabase auth cookies. Verify this behavior on the selected Workers adapter before deployment.
- The practice library routes (`/chapterwise`, `/chapter-practice`, `/pyq`) and `/profile` now render route shells and load their data in the browser. These are compatible with Workers too, but keep RLS protections and clear loading/error states.
- PYQ grading calls the `grade_jee_pyq` Supabase RPC. Preserve database-side authorization and attempt ownership.
- No successful Workers build or production deployment has been verified yet.

## Implementation sequence

1. Inspect the complete Next.js route/features inventory and check adapter compatibility for this Next.js version, Proxy, Server Actions, and Supabase SSR.
2. Install the selected adapter and Wrangler through a real package-manager operation, regenerating `package-lock.json` in the same change. Never hand-edit dependency lock data.
3. Add the official Worker config and adapter config, using `nodejs_compat` and a current compatibility date. Keep generated `.open-next` output out of Git if OpenNext is selected.
4. Add separate scripts for adapter build, local Worker preview, and deployment. Keep `next dev` available for existing development workflow.
5. Configure Cloudflare Workers Builds (not the Pages static build) with the correct install/build commands and environment variables. Configure Supabase public URL/key as appropriate and keep all service-role secrets server-only.
6. Run lint, typecheck, unit tests, Playwright, Next.js production build, adapter build, and local Worker preview. Test login, OAuth callback, reset password, cookie refresh, PYQ grading, daily challenge, mock-test start/resume/submit, admin authorization, and private profile data.
7. Deploy to a Worker preview URL, verify production-like smoke tests and logs, then configure the custom domain only after acceptance checks pass.

## Security and release gates

- Never expose a Supabase service-role key to browser code.
- Do not replace admin or ownership checks with client-side UI checks.
- Confirm private tables and RPCs enforce authorization in Postgres/Supabase.
- Do not claim success until the Worker build and critical browser journeys pass.
- Vercel check failures caused by Vercel's deployment quota are unrelated to the Cloudflare Workers deployment; configure the intended CI/deployment checks explicitly.
