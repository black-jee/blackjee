import { describe, expect, it } from "vitest";
import { isValidIstLocalDateTime, istLocalDateTimeToIso } from "@/lib/time/ist-local-date-time";

describe("India-local datetime validation", () => {
  it("accepts valid dates and leap days", () => {
    expect(isValidIstLocalDateTime("2024-02-29T23:59")).toBe(true);
    expect(isValidIstLocalDateTime("2026-10-24T00:00")).toBe(true);
  });

  it("rejects dates that Date.parse might normalize", () => {
    expect(isValidIstLocalDateTime("2026-02-31T10:00")).toBe(false);
    expect(isValidIstLocalDateTime("2025-02-29T10:00")).toBe(false);
    expect(isValidIstLocalDateTime("2026-13-01T10:00")).toBe(false);
  });

  it("rejects out-of-range time components and malformed values", () => {
    expect(isValidIstLocalDateTime("2026-10-24T24:00")).toBe(false);
    expect(isValidIstLocalDateTime("2026-10-24T10:60")).toBe(false);
    expect(isValidIstLocalDateTime("2026-10-24 10:00")).toBe(false);
  });

  it("converts valid India-local time to UTC", () => {
    expect(istLocalDateTimeToIso("2026-10-24T10:00")).toBe("2026-10-24T04:30:00.000Z");
  });

  it("throws rather than converting an invalid local datetime", () => {
    expect(() => istLocalDateTimeToIso("2026-02-31T10:00")).toThrow(
      "Invalid India-local date and time.",
    );
  });
});
