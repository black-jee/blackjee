#!/usr/bin/env node
import { readFileSync } from "node:fs";

const checks = [
  {
    file: "supabase/migrations/20261024130000_harden_mock_test_input_nulls.sql",
    description: "mock-test RPC rejects NULL mode and bounds",
    pattern:
      /p_mode\s+is\s+null\s+or\s+p_mode\s+not\s+in\s*\('shift','focused'\)[\s\S]*?p_question_count\s+is\s+null\s+or\s+p_duration_seconds\s+is\s+null/i,
  },
  {
    file: "supabase/migrations/20261024130000_harden_mock_test_input_nulls.sql",
    description: "security-definer mock-test RPC pins search_path",
    pattern: /security\s+definer[\s\S]*?set\s+search_path\s+to\s+''/i,
  },
  {
    file: "supabase/migrations/20261025110000_harden_daily_challenge_authoring_integrity.sql",
    description: "daily challenge RPC enforces solution and option integrity",
    pattern:
      /A live challenge must include a worked solution[\s\S]*?A daily challenge can have at most 12 options[\s\S]*?Daily challenge options need non-empty labels[\s\S]*?Daily challenge option labels must be unique[\s\S]*?Correct answer must match one of the option labels/i,
  },
  {
    file: "supabase/migrations/20261025100000_enforce_unique_pyq_option_labels.sql",
    description: "PYQ option integrity guard checks non-empty labels",
    pattern: /Single-correct options need non-empty labels/,
  },
  {
    file: "supabase/migrations/20261025100000_enforce_unique_pyq_option_labels.sql",
    description: "PYQ option integrity guard rejects duplicate labels case-insensitively",
    pattern:
      /group\s+by\s+upper\s*\(\s*btrim\s*\(\s*coalesce\s*\([\s\S]*?having\s+count\s*\(\s*\*\s*\)\s*>\s*1/i,
  },
  {
    file: "supabase/migrations/20261025100000_enforce_unique_pyq_option_labels.sql",
    description: "PYQ option integrity guard is attached to question writes",
    pattern:
      /create\s+trigger\s+validate_jee_pyq_option_labels[\s\S]*?before\s+insert\s+or\s+update\s+of\s+question_type\s*,\s*options/i,
  },
  {
    file: "supabase/migrations/20261025110000_harden_daily_challenge_authoring_integrity.sql",
    description: "daily challenge RPC rejects live challenges without worked solutions",
    pattern:
      /coalesce\(p_is_live,\s*false\)[\s\S]*?nullif\(btrim\(p_solution\),\s*''\)\s+is\s+null[\s\S]*?A live challenge must include a worked solution/i,
  },
  {
    file: "supabase/migrations/20261025110000_harden_daily_challenge_authoring_integrity.sql",
    description: "daily challenge RPC validates option count, unique labels and answer match",
    pattern:
      /jsonb_array_length\(p_options\)\s*>\s*12[\s\S]*?Daily challenge option labels must be unique[\s\S]*?Correct answer must match one of the option labels/i,
  },
  {
    file: "supabase/reconstruction/tests/run_rpc_negative_tests.sh",
    description: "daily challenge RPC regressions cover duplicate labels and mismatched answers",
    pattern:
      /daily challenge RPC rejects duplicate option labels[\s\S]*?daily challenge RPC rejects answer not present in options/i,
  },
  {
    file: "supabase/reconstruction/tests/run_rpc_negative_tests.sh",
    description: "direct RPC regression covers blank live-challenge solutions",
    pattern:
      /live daily challenge cannot be saved without a worked solution[\s\S]*?A live challenge must include a worked solution/i,
  },
  {
    file: "supabase/reconstruction/004_reconstructed_access_grants.sql",
    description: "browser roles cannot access private schema directly",
    pattern:
      /revoke\s+all\s+on\s+schema\s+private\s+from\s+public\s*,\s*anon\s*,\s*authenticated\s*,\s*service_role/i,
  },
  {
    file: "supabase/tests/private_table_access.sql",
    description: "private-table access regression checks include private schema usage",
    pattern:
      /has_schema_privilege\('anon',\s*'private',\s*'usage'\)[\s\S]*?has_schema_privilege\('authenticated',\s*'private',\s*'usage'\)/i,
  },
  {
    file: "supabase/reconstruction/tests/run_rpc_negative_tests.sh",
    description: "cross-user mock attempt resume, submit and result are tested",
    pattern:
      /cannot resume another user's mock attempt[\s\S]*?cannot submit another user's mock attempt[\s\S]*?cannot retrieve another user's mock-test result/i,
  },
  {
    file: "supabase/tests/pyq_option_label_validation.sql",
    description: "numerical questions with an empty options array remain valid",
    pattern:
      /Numerical questions intentionally have no multiple-choice options[\s\S]*?'numerical',\s*'\[\]'::jsonb/i,
  },
  {
    file: "supabase/tests/public_schedule_rpc_security.sql",
    description: "challenge statement and options are not directly selectable by browser roles",
    pattern: /Browser roles must not directly read challenge statements or options/,
  },
  {
    file: ".github/workflows/ci.yml",
    description: "CI executes database option-integrity and authorization regressions",
    pattern: /supabase\/tests\/pyq_option_label_validation\.sql[\s\S]*?run_rpc_negative_tests\.sh/,
  },

  {
    file: "lib/auth/require-admin.ts",
    description:
      "administrator pages use authenticated server-managed app metadata, not user-editable metadata",
    pattern: /supabase\.auth\.getUser\(\)[\s\S]*?app_metadata\?\.role\s*!==\s*"admin"/,
  },
  {
    file: "app/admin/actions.ts",
    description: "daily-challenge authoring verifies server-managed administrator role before RPC",
    pattern:
      /supabase\.auth\.getUser\(\)[\s\S]*?auth\.user\.app_metadata\?\.role\s*!==\s*"admin"[\s\S]*?supabase\.rpc\(\s*"admin_save_daily_challenge"/,
  },
  {
    file: "app/admin/pyq/actions.ts",
    description:
      "PYQ authoring and review verify server-managed administrator role before privileged RPCs",
    pattern:
      /supabase\.auth\.getUser\(\)[\s\S]*?app_metadata\?\.role\s*!==\s*"admin"[\s\S]*?supabase\.rpc\(\s*"admin_save_jee_pyq_question"[\s\S]*?supabase\.rpc\(\s*"admin_review_jee_pyq_question"/,
  },
];

let failed = 0;
for (const check of checks) {
  let source;
  try {
    source = readFileSync(check.file, "utf8");
  } catch (error) {
    console.error(`FAIL: ${check.description} (cannot read ${check.file}: ${error.message})`);
    failed++;
    continue;
  }
  if (check.pattern.test(source)) {
    console.log(`PASS: ${check.description}`);
  } else {
    console.error(`FAIL: ${check.description} [${check.file}]`);
    failed++;
  }
}

if (failed > 0) {
  console.error(`Security contract checks failed: ${failed}/${checks.length}`);
  process.exitCode = 1;
} else {
  console.log(`Security contract checks passed: ${checks.length}/${checks.length}`);
}
