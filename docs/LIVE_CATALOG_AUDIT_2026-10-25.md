# Live Supabase catalog and privilege audit — 2026-10-25

## Scope and method

- **Target:** BLACK-JEE Supabase project `phdssyexhfyxsmhmmcgb`.
- **Method:** read-only PostgreSQL catalog queries through the connected Supabase project.
- **Mutations:** none. No DDL, data writes, grants, migration apply/repair/reset, content publication, or branch creation.
- **Important:** these results describe the live catalog at query time. They are not a complete live-versus-reconstruction diff and do not prove runtime behavior under real user JWTs.

## Live catalog inventory

| Object                  | Count / result |
| ----------------------- | -------------: |
| Tables                  |              9 |
| Columns                 |             93 |
| Constraints             |             49 |
| Indexes                 |             23 |
| RLS policies            |             10 |
| Functions               |             12 |
| Definer functions       |             11 |
| RLS-enabled tables      |          9 of 9 |
| FORCE RLS tables        |          0 of 9 |
| Definer path non-empty  |              0 |

Counts are useful inventory checks only; they do not establish definition-level equivalence.

## Direct access and privileged RPCs

- The `private` schema reports no `USAGE` privilege for `anon`, `authenticated`, or `service_role`.
- All five private application tables deny direct `SELECT`, `INSERT`, `UPDATE`, and `DELETE` to both `anon` and `authenticated`.
- All 11 public `SECURITY DEFINER` functions deny `EXECUTE` to `anon`; `authenticated` and `service_role` have `EXECUTE` on the listed functions.
- All 11 public definer functions have an empty pinned `search_path` in `proconfig`. A separate text scan found no authenticated-callable public definer function missing the literal `auth.uid()` check. This is a heuristic, not proof that each function's authorization logic is correct; function-by-function review and JWT tests are still required.
- The 10 live RLS policies currently cover own challenge attempts, admin-only challenge writes, live schedule reads, admin-only PYQ writes, published/approved PYQ plus admin-queue reads, and own mock-test-attempt reads. Admin predicates use `app_metadata.role = 'admin'`, not user-editable profile metadata.

## Migration ledger snapshot

The live Supabase migration API returned **20 applied versions** at this audit. Existing reconciliation notes report seven applied versions whose historical SQL bodies were not recovered in the repository, plus repository migration files absent from the live ledger. This audit does not resolve those differences. Do not invent historical SQL, rewrite the live ledger, or apply reconstruction-only migrations to production.

## Next comparison needed

A reliable parity report must compare normalized definitions—not only counts—for:

1. every table column (type, nullability, default, identity/generated attributes);
2. primary/unique/check/foreign-key constraints, including FK actions;
3. index expressions, predicates, and included columns;
4. each RLS policy's command, roles, `USING`, and `WITH CHECK`;
5. effective schema/table/column/routine grants;
6. routine identity, definition fingerprints, security mode, configuration, and ACLs.

The repository's disposable PostgreSQL replay remains a separate test environment. Live catalog reads cannot establish that the replay is historically equivalent to the seven missing migration bodies.

## Verification boundary

This is a **read-only live catalog audit**. It does not test real Supabase-issued anonymous/student/admin JWTs, authenticated browser journeys, or the deployed Vercel runtime. The branch-only PYQ option-label trigger and `private.mock_test_responses(question_id)` index remain separate from production unless a fresh live query establishes otherwise. Draft PR #2 remains open and unmerged.
