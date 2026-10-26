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

## Deployment log finding (2026-10-26)

The Cloudflare Workers build log confirms that `npm run build` and the OpenNext adapter build both succeeded. OpenNext generated `.open-next/worker.js`, and Cloudflare accepted all 86 static assets. Deployment then failed with Wrangler error `10143`: the `WORKER_SELF_REFERENCE` service binding pointed to a Worker named `black-jee` that Cloudflare could not find, while the auto-detected Worker name was `blackjee`.

This is a Worker configuration/deployment failure, not a Next.js compilation failure. Before retrying:

1. Commit a project-owned `wrangler.jsonc` and `open-next.config.ts`; do not depend on the transient automatic migration in a Workers Builds job.
2. Make the Wrangler `name` the canonical Worker name (`blackjee`) and set `main` to `.open-next/worker.js`, `assets.directory` to `.open-next/assets`, and `assets.binding` to `ASSETS`. Enable `nodejs_compat` and observability.
3. Review why `WORKER_SELF_REFERENCE` is present. The standard OpenNext setup does not require adding it indiscriminately; retain it only if the selected features/cache configuration need it, and if retained its `service` must exactly match an existing Worker name. Do not change names by guesswork.
4. Install `@opennextjs/cloudflare` and `wrangler` as project dev dependencies using npm, then commit `package.json` and the regenerated `package-lock.json` together. Do not rely on `npx` downloading undeclared packages during deployment.
5. Preview locally and verify the deployed Worker, especially Supabase auth-cookie refresh through `proxy.ts`; OpenNext emitted an experimental Node.js middleware warning in this build.

## Explicit Cloudflare Workers build configuration

A committed `wrangler.jsonc` now defines the Worker name as `blackjee`, the OpenNext entrypoint and assets directory, `nodejs_compat`, the `IMAGES` binding, observability, and a self-reference service binding whose service name exactly matches `blackjee`. This directly addresses the mismatch shown in the deployment log (the generated binding targeted `black-jee`, while the Worker name was `blackjee`).

The package scripts now include `worker:build`, `worker:preview`, and `worker:deploy`. Configure Cloudflare Workers Builds to run:

- Build command: `npm run worker:build`
- Deploy command: `npm run worker:deploy`

Do not keep the old combination of `npm run build` followed by `npx wrangler deploy`: that builds only the ordinary Next.js output and bypasses the explicit OpenNext adapter workflow once a project-owned Wrangler configuration exists.

The scripts currently invoke the adapter through `npx`, so the adapter and Wrangler are not yet pinned as project dev dependencies in `package.json` / `package-lock.json`. A follow-up hardening step is to add both using npm and commit the regenerated lockfile; until then, adapter versions are not reproducibly pinned. After configuration changes, rerun the Workers build and deployment, then verify the deployed URL and Supabase auth-cookie refresh. The local build log alone does not establish that deployment now succeeds.


### Dependency and CI limitation

The adapter configuration file `open-next.config.ts` is intentionally not committed yet: it imports `@opennextjs/cloudflare`, which is absent from the committed dependency tree, and a clean `npm ci` would not resolve that import. The Worker scripts currently use `npx --yes` to fetch the CLI at runtime. This is a transitional, unpinned setup, not a reproducible production build. Before treating the migration as complete, install `@opennextjs/cloudflare` and `wrangler` as dev dependencies using npm, commit the matching regenerated `package-lock.json`, restore a typed OpenNext config if needed, and require CI to run the Worker build. The current GitHub Actions CI run is pending; no result is inferred from its pending state.
