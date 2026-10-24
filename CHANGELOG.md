# Changelog

Meaningful project changes are recorded here. This is not a claim that production has been deployed.

## 2026-10-24 — Engineering governance and PYQ safety

- Added the constitution-aligned project context, task ledger, engineering decisions, release register, and SEO/growth plan.
- Reconciled the live PYQ publish gate: source document and page, non-empty statement, private answer key, worked solution, and option-label validation for single-correct questions.
- Verified live database grants: anonymous role cannot execute the admin review RPC; authenticated role can call the RPC, which enforces admin authorization internally.
- Confirmed five PYQs exist and zero are published.
- Recorded that authenticated browser journeys, production deployment linkage/runtime, and clean database replay remain unverified.
