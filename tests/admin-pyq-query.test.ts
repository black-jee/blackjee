import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const adminPyqPage = readFileSync(resolve(process.cwd(), "app/admin/pyq/page.tsx"), "utf8");

describe("admin PYQ query column permissions", () => {
  it("does not request publication_block_reason without an authenticated SELECT grant", () => {
    const selectMatch = adminPyqPage.match(/\.select\(\s*"([^"]+)"/);
    expect(selectMatch, "admin PYQ page should use an explicit select list").not.toBeNull();

    const selectedColumns = selectMatch?.[1].split(",").map((column) => column.trim()) ?? [];
    expect(selectedColumns).toContain("source_status");
    expect(selectedColumns).toContain("review_status");
    expect(selectedColumns).not.toContain("publication_block_reason");
    expect(adminPyqPage).not.toContain("question.publication_block_reason");
  });
});
