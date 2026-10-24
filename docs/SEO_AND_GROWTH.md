# SEO and growth plan

## Current evidence

- Stack is Next.js App Router, suitable for server-rendered/indexable public study content.
- Production URL supplied by owner: https://blackjee.vercel.app/; production crawlability, metadata, sitemap, robots, canonical URLs, analytics and Search Console status have not been verified.
- Do not index authenticated dashboards, student history, unpublished questions, answer keys, or protected challenge payloads.

## Priorities

1. **P1 trust and release safety:** only publish verified educational content with source provenance and reviewed solutions.
2. **P2 technical SEO:** audit page titles/descriptions, canonical URLs, sitemap, robots, redirects, status codes, Open Graph metadata and internal navigation.
3. **P2 useful content:** create crawlable chapter and exam resources with original, accurate educational value; avoid thin/duplicated question pages.
4. **P3 performance/accessibility:** measure mobile LCP/CLS/INP and keyboard/screen-reader behavior before setting budgets or optimizing.
5. **P3 feedback:** collect student feedback with minimal personal data; document consent and retention before adding analytics.

## Guardrails

- Never invent user counts, success rates, testimonials or rank guarantees.
- Do not expose private student data or unpublished content through metadata, sitemaps, static payloads or caches.
- Use structured data only when the page qualifies and the data is accurate.
- Measure baseline before proposing performance budgets or growth experiments.

## Next audit
Verify production response status and rendered metadata; inspect `app/robots.ts`, `app/sitemap.ts`, route metadata and public/private route boundaries. Record each finding in `docs/TASKS.md` with evidence.
