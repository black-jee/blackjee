# Reconstructed schema workspace

This folder contains clearly labelled reconstruction artifacts, not original migrations.

## Files

- `001_reconstructed_table_shapes.sql`: first structural draft for the nine observed application tables in `public` and `private`. Derived from read-only table metadata; it is not replay-ready or security-complete.

## Required before replay

- Capture exact nullability, FK update/delete actions, constraints, indexes, RLS policies, grants, function bodies/owners/configuration/ACLs, extension versions, and storage configuration.
- Reconcile the applied `20261024112132` publication guard with the two local-only guard files.
- Correct this draft against the exact catalog snapshot.
- Replay only in a disposable, no-cost PostgreSQL-compatible database.
- Compare the replay with the reference snapshot and run role-based security tests.

Never apply this folder to the production Supabase project. Never copy these files into `supabase/migrations/` until reviewed and replay-tested. Original historical SQL bodies remain missing; these files must not be represented as recovered originals.
