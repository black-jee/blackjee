import { describe, expect, it } from "vitest";
import { isSafeAssetPath, questionContentSchema } from "../lib/questions/schema";
import {
  isValidIstLocalDateTime,
  istLocalDateTimeToIso,
} from "../lib/time/ist-local-date-time";

describe("questionContentSchema", () => {
  it("accepts a basic question with math-bearing text and image options", () => {
    const result = questionContentSchema.safeParse({
      sourceId: "BJ-JM-2026-S1-PHY-032",
      statement: "Find the value of \\(v^2\\).",
      subject: "Physics",
      options: [{ id: "a", label: "A", text: "Option A", imagePath: "assets/q32-a.png" }],
    });
    expect(result.success).toBe(true);
  });

  it("rejects empty statements and invalid subjects", () => {
    expect(
      questionContentSchema.safeParse({ sourceId: "q1", statement: "", subject: "Biology" })
        .success,
    ).toBe(false);
  });
});

describe("isSafeAssetPath", () => {
  it("accepts a relative asset path", () => {
    expect(isSafeAssetPath("assets/questions/q1.png")).toBe(true);
  });

  it.each([
    "../secret.png",
    "/etc/passwd",
    "assets/../secret.png",
    "https://example.com/x.png",
    "assets\\secret.png",
    "assets//empty.png",
  ])("rejects unsafe path %s", (path) => {
    expect(isSafeAssetPath(path)).toBe(false);
  });
});

describe("India-local schedule datetime validation", () => {
  it.each([
    "2026-10-24T16:30",
    "2024-02-29T00:00",
    "2000-02-29T23:59",
  ])("accepts valid datetime %s", (value) => {
    expect(isValidIstLocalDateTime(value)).toBe(true);
  });

  it.each([
    "2026-02-29T12:00",
    "2026-04-31T12:00",
    "2026-13-01T12:00",
    "2026-10-24T24:00",
    "2026-10-24T12:60",
    "2026-10-24",
    "2026-10-24T12:00:00",
  ])("rejects invalid datetime %s", (value) => {
    expect(isValidIstLocalDateTime(value)).toBe(false);
  });

  it("converts a valid India-local datetime to UTC", () => {
    expect(istLocalDateTimeToIso("2026-10-24T16:30")).toBe("2026-10-24T11:00:00.000Z");
  });

  it("throws rather than normalizing an invalid datetime", () => {
    expect(() => istLocalDateTimeToIso("2026-02-31T12:00")).toThrow();
  });
});
