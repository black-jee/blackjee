# Live Supabase catalog and privilege audit — 2026-10-25

## Scope and method

- **Target:** BLACK-JEE Supabase project `phdssyexhfyxsmhmmcgb`.
- **Method:** read-only PostgreSQL catalog queries through the connected Supabase project.
- **Mutations:** none. No DDL, data writes, grants, migration apply/repair/reset, content publication, or branch creation.
- **Important:** these results describe the live catalog at query time. They are not a complete live-versus-reconstruction diff and do not prove runtime behavior under real user JWTs.

## Live catalog inventory

- Tables: 9
- Columns: 93
- Constraints: 49
- Indexes: 23
- RLS policies: 10
- Functions: 12, including 11 `SECURITY DEFINER` functions
- Tables with RLS enabled: 9 of 9
- Tables with FORCE ROW LEVEL SECURITY: 0 of 9
- Definer functions with a non-empty or unset `search_path`: 0

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

## Follow-up read-only snapshot — 2026-10-25

The Supabase management API and PostgreSQL catalog were queried again after the initial report:

- The migration API returned 20 applied versions, from `20261024080824` (`foundation_schema`) through `20261024112132` (`require_pyq_source_page_before_publish`). The complete live list is available from the connected project's migration API; this report does not reproduce missing historical bodies.
- The live table API returned nine application tables across `public` and `private`, all with RLS enabled. The detailed response includes column types/defaults/checks, primary keys, and foreign keys; the earlier inventory count was 93 columns and 49 constraints.
- A normalized access snapshot returned 10 policies, 12 routines, 36 table-grant rows, and 460 column-grant rows for the selected application schemas/roles.
- The effective privilege check returned no direct `SELECT`, `INSERT`, `UPDATE`, or `DELETE` table grants to `anon` or `authenticated` on `private` tables. It returned no `PUBLIC EXECUTE` grant among the 12 routines and only `get_current_daily_challenge()` executable by `anon`. The 11 remaining routines are not executable by `anon`; authenticated and service roles can execute them.
- `public` has `USAGE` for the browser roles and no `CREATE` for `anon`, `authenticated`, or `service_role`; `private` denies `USAGE` to those three roles.

### CI verification after formatting correction

GitHub Actions run [40184262757](https://github.com/black-jee/blackjee/actions/runs/40184262757) completed successfully. Both `quality` and `reconstruction-replay` concluded `success`. This verifies the repository CI jobs on the formatting correction; it does not establish that the separate Vercel deployment succeeded.

### Remaining parity work

This is still an access/catalog inventory, not a full definition-level diff. Exact live-versus-repository comparison of every column attribute, constraint action, index definition, policy expression, grant, and routine definition remains open. Migration history reconciliation also remains open: the known seven missing applied migration bodies and six repository-only migration files must be matched by version and recovered from trustworthy source material, not reconstructed by guesswork. No live database changes were made.

## Security advisor follow-up — 2026-10-25

The Supabase security advisor currently reports:

- Five informational `rls_enabled_no_policy` findings for private answer-key/session/response tables. These tables intentionally have RLS enabled with no direct-client policies, and the catalog check found no browser-role `USAGE` on `private` and no direct browser CRUD grants. This is defense in depth; RPC access still needs runtime tests.
- Eleven warnings for authenticated execution of `SECURITY DEFINER` routines exposed in `public`. This is not by itself proof of an authorization bypass. Read-only inspection of the live definitions showed each of the 11 routines references `auth.uid()`; the three admin authoring/review routines also check the trusted `auth.jwt()->'app_metadata'->>'role' = 'admin'` claim. The user-scoped routines constrain queried or mutated attempts to the caller's user ID, and routines pin `search_path` to empty. These static observations are encouraging but do not replace negative runtime tests using real issued JWTs, including ordinary authenticated users invoking each admin routine and cross-user attempt IDs.
- No security advisor finding was remediated in production during this pass. The intended role model and runtime validation gap should be documented and reviewed before any approved production security change.

