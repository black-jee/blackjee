# Reconstructed schema baseline — working area

**Status: NOT executable; NOT a migration; NOT verified by replay.**

This directory is reserved for a replacement schema reconstruction if the original seven migration bodies cannot be recovered. The original history remains incomplete, and the live project must not be reset, repaired, or changed to make the repository appear consistent.

## Why we are not filling the missing versioned files directly

The missing migration names do not uniquely determine their SQL. Inventing files under the original version identifiers would falsely imply historical authenticity and could hide order-dependent grants, policies, constraints, and function behavior. The two local-only publication-guard migrations also conflict with the applied version ledger.

## Reconstruction strategy

1. Treat the current Supabase catalog as a read-only reference snapshot, not as permission to modify production.
2. Export exact definitions for all nine application tables across `public` and `private`, including columns, defaults, constraints, indexes, RLS flags, grants, and policies.
3. Export all application functions with full bodies, owners, `SECURITY DEFINER/INVOKER`, `search_path`, and execute ACLs.
4. Record extensions and relevant storage configuration. The current inventory observed no application storage buckets.
5. Assemble new baseline SQL in this directory, with each reconstructed file named `RECONSTRUCTED` or otherwise clearly labelled. Do not put these files in `supabase/migrations/` until the full chain and replay are reviewed.
6. Reconcile the page-number publication guard against the live catalog and the applied `20261024112132` ledger record. Retain one canonical guard in the eventual replay sequence.
7. Replay from an empty disposable PostgreSQL-compatible database, then compare schema, function behavior, grants, and RLS against the read-only snapshot.
8. Only after replay equivalence and security tests pass, propose a separate reviewed migration-chain change. Never apply reconstruction files to the production target as a shortcut.

## Current snapshot evidence

- Live history: 20 versions.
- Repository migration SQL files: 15.
- Exact filename/version matches: 13.
- Missing applied SQL bodies: 7.
- Local-only publication guard files: 2.
- Application tables in `public` and `private`: 9, all observed with RLS enabled.
- Application triggers: 0 in the prior read-only inventory.
- Clean replay: not yet tested.
- No-cost constraint: do not create a billable Supabase branch/project. Use a disposable local/container Postgres service or an existing no-cost CI runner after checking its capabilities.

## Acceptance checklist

- [ ] Complete schema and ACL snapshot captured
- [ ] All function bodies and configuration captured
- [ ] Reconstructed SQL clearly distinguished from original historical SQL
- [ ] Publication guard lineage reconciled
- [ ] Fresh replay succeeds from empty database
- [ ] Object/ACL comparison to reference snapshot passes
- [ ] Anonymous, student, owner, and admin security tests pass
- [ ] CI runs the SQL checks without production secrets
- [ ] Documentation states remaining differences honestly

Until these gates pass, the repository must continue to state that clean replay is unverified.
