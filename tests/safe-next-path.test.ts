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
    "/\\\\evil.example",
    "https://evil.example/path",
    "\\\\evil.example",
    "profile",
  ])("rejects external or non-root-relative destination %s", (requestedNext) => {
    expect(safeInternalRedirectPath(requestedNext, origin)).toBe("/");
  });

  it("uses the root path when the destination is missing", () => {
    expect(safeInternalRedirectPath(null, origin)).toBe("/");
  });
});
