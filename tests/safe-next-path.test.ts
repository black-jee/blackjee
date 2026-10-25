import { describe, expect, it } from "vitest";
import { safeInternalRedirectPath } from "../lib/auth/safe-next-path";

describe("safeInternalRedirectPath", () => {
  const origin = "https://blackjee.example";

  it("keeps same-origin paths, query strings, and fragments", () => {
    expect(safeInternalRedirectPath("/profile?tab=security#sessions", origin)).toBe(
      "/profile?tab=security#sessions",
    );
  });

  it.each([
    "//evil.example",
    "/" + String.fromCharCode(92) + "evil.example",
    "https://evil.example/path",
    String.fromCharCode(92) + "evil.example",
    "profile",
  ])("rejects external or non-root-relative destination %s", (requestedNext) => {
    expect(safeInternalRedirectPath(requestedNext, origin)).toBe("/");
  });

  it("uses the root path when the destination is missing", () => {
    expect(safeInternalRedirectPath(null, origin)).toBe("/");
  });

  it("validates root-relative paths without requiring a browser origin", () => {
    expect(safeInternalRedirectPath("/profile?tab=security")).toBe("/profile?tab=security");
    expect(safeInternalRedirectPath("//evil.example")).toBe("/");
  });
});
