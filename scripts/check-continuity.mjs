import { existsSync, readFileSync } from "node:fs";

const required = [
  "docs/CONTINUITY_SYSTEM_PROMPT.md",
  "docs/PROJECT_CONTEXT.md",
  "docs/PROJECT_STATUS.md",
  "docs/SESSION_HANDOVER.md",
  "docs/TASKS.md",
  "docs/DECISIONS.md",
  "docs/VERIFICATION_LOG.md",
];

const failures = [];

for (const path of required) {
  if (!existsSync(path)) {
    failures.push(`Missing required continuity file: ${path}`);
    continue;
  }

  if (!readFileSync(path, "utf8").trim()) {
    failures.push(`Required continuity file is empty: ${path}`);
  }
}

if (failures.length === 0) {
  const tasks = readFileSync("docs/TASKS.md", "utf8");
  const handover = readFileSync("docs/SESSION_HANDOVER.md", "utf8");
  const taskIds = [...tasks.matchAll(/^### (BJ-[A-Z]+-\d+) —/gm)].map(
    (match) => match[1],
  );
  const duplicateIds = taskIds.filter(
    (id, index) => taskIds.indexOf(id) !== index,
  );

  if (duplicateIds.length > 0) {
    failures.push(
      `Duplicate task IDs in docs/TASKS.md: ${[...new Set(duplicateIds)].join(", ")}`,
    );
  }

  const activeTask = handover.match(
    /^\*\*Active task:\*\* (BJ-[A-Z]+-\d+)/m,
  )?.[1];

  if (!activeTask) {
    failures.push(
      "SESSION_HANDOVER.md must declare one Active task with a permanent BJ-* ID.",
    );
  } else if (!taskIds.includes(activeTask)) {
    failures.push(
      `Active handover task ${activeTask} is missing from docs/TASKS.md.`,
    );
  }

  if (!/^## Single exact next action\s*$/m.test(handover)) {
    failures.push(
      "SESSION_HANDOVER.md must contain the heading 'Single exact next action'.",
    );
  }
}

if (failures.length > 0) {
  console.error("Continuity validation failed:");
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log(
  `Continuity validation passed: ${required.length} required files are present and non-empty; task IDs and handover pointer are consistent.`,
);
