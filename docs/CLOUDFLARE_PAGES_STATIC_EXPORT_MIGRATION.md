# Cloudflare Workers Migration

## Goal

Run BLACK-JEE as a full-stack Next.js application on Cloudflare Workers. Keep Next.js server rendering, Server Actions, Route Handlers, and Supabase authentication working where needed. Do not enable `output: "export"` or target the Cloudflare Pages static `out/` directory.

## Deployment approach

Cloudflare's current Next.js guidance recommends **vinext** as the default for new Workers deployments. vinext is still in beta, so its own compatibility check must be reviewed against BLACK-JEE before adopting it. Its initializer for an existing Next.js 16 app is described as non-destructive and keeps the regular `next dev` workflow available while the Worker path is evaluated.

**Do not install an adapter based on documentation alone.** First run the compatibility check in a disposable checkout or CI job:

```sh
npx vinext check
```

Review its output and the [vinext compatibility dashboard](https://developers.cloudflare.com/workers/framework-guides/web-apps/nextjs/). If required features are unsupported or the compatibility report is not acceptable, evaluate the documented OpenNext Cloudflare adapter instead. Only then run the selected adapter's initializer/install command, inspect every generated change, and commit package metadata and lockfile together using npm.

Official references:
- Cloudflare Next.js on Workers / vinext: https://developers.cloudflare.com/workers/framework-guides/web-apps/nextjs/
- Cloudflare OpenNext adapter: https://developers.cloudflare.com/workers/framework-guides/web-apps/opennext/
- OpenNext migration guide: https://opennext.js.org/cloudflare/get-started

## Current repository state

- The app uses Next.js 16 and Supabase.
- Server Actions exist in admin, daily challenge, mock-test, and PYQ code.
- The existing `app/auth/callback/route.ts` performs the OAuth PKCE code exchange on the server and writes session cookies to the redirect response. Keep this server route unless a verified adapter limitation requires a replacement; test the full OAuth redirect and cookie persistence end-to-end.
- `proxy.ts` refreshes Supabase auth cookies. Verify this behavior on the selected Workers adapter before deployment.
- The practice library routes (`/chapterwise`, `/chapter-practice`, `/pyq`) and `/profile` now render route shells and load their data in the browser. Keep RLS protections and clear loading/error states.
- PYQ grading calls the `grade_jee_pyq` Supabase RPC. Preserve database-side authorization and attempt ownership.
- No successful Workers build or production deployment has been verified yet.

## Implementation sequence

1. Inventory all routes, middleware/proxy behavior, Server Actions, Node-specific APIs, and Supabase SSR usage. Run `npx vinext check` and review its findings before choosing the adapter.
2. Install the selected adapter and Wrangler through a real package-manager operation, regenerating `package-lock.json` in the same change. Never hand-edit dependency lock data.
3. Add the official Worker config and adapter config, using `nodejs_compat` where required and a current compatibility date. Keep generated `.open-next` output out of Git if OpenNext is selected.
4. Add separate scripts for adapter build, local Worker preview, and deployment. Keep `next dev` available for the existing development workflow.
5. Configure Cloudflare **Workers Builds**, not the Pages static build, with the correct install/build commands and environment variables. Configure Supabase public URL/key as appropriate and keep all service-role secrets server-only.
6. Run lint, typecheck, unit tests, Playwright, Next.js production build, adapter build, and local Worker preview. Test login, OAuth callback and cookie persistence, reset password, cookie refresh, PYQ grading, daily challenge, mock-test start/resume/submit, admin authorization, and private profile data.
7. Deploy to a Worker preview URL, verify production-like smoke tests and logs, then configure the custom domain only after acceptance checks pass.

## Security and release gates

- Never expose a Supabase service-role key to browser code.
- Do not replace admin or ownership checks with client-side UI checks.
- Confirm private tables and RPCs enforce authorization in Postgres/Supabase.
- Do not claim success until the Worker build and critical browser journeys pass.
- Vercel's reported deployment-quota failure is separate from Cloudflare Workers. The latest Cloudflare Pages failure also does not validate a Workers build; switch deployment configuration only after the selected Worker adapter builds and previews successfully.
