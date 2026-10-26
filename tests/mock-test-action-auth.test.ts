import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const mockTestActions = readFileSync(resolve(process.cwd(), "app/mock-tests/actions.ts"), "utf8");

describe("mock-test server action authentication contract", () => {
  it("derives the caller from Supabase's verified user session", () => {
    expect(mockTestActions).toMatch(/supabase\.auth\.getUser\(\)/);
    expect(mockTestActions).toContain("if (error || !data.user) return { supabase, userId: null }");
    expect(mockTestActions).not.toMatch(/auth\.getSession\(\)/);
  });

  it.each([
    ["startMockTest", "start_mock_test", "Sign in to start a mock test."],
    ["resumeMockTest", "resume_mock_test", "Sign in to resume this test."],
    ["submitMockTest", "submit_mock_test", "Sign in to submit this test."],
  ])("%s rejects unauthenticated callers before calling %s", (action, rpc, message) => {
    const start = mockTestActions.indexOf(`export async function ${action}(`);
    expect(start, `${action} should be exported`).toBeGreaterThanOrEqual(0);
    const nextExport = mockTestActions.indexOf("\nexport async function ", start + 1);
    const body = mockTestActions.slice(start, nextExport === -1 ? undefined : nextExport);
    const authGuard = body.indexOf("if (!userId)");
    const rpcCall = body.indexOf(`.rpc("${rpc}"`);

    expect(authGuard, `${action} must reject missing users`).toBeGreaterThanOrEqual(0);
    expect(body).toContain(message);
    expect(rpcCall, `${action} must call the expected RPC`).toBeGreaterThan(authGuard);
  });
});
