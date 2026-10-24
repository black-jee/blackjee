import { describe, expect, it } from "vitest";
import { isSafeAssetPath, questionContentSchema } from "../lib/questions/schema";

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
    expect(questionContentSchema.safeParse({ sourceId: "q1", statement: "", subject: "Biology" }).success).toBe(false);
  });
});

describe("isSafeAssetPath", () => {
  it("accepts a relative asset path", () => {
    expect(isSafeAssetPath("assets/questions/q1.png")).toBe(true);
  });

  it.each(["../secret.png", "/etc/passwd", "assets/../secret.png", "https://example.com/x.png", "assets\\secret.png", "assets//empty.png"])("rejects unsafe path %s", (path) => {
    expect(isSafeAssetPath(path)).toBe(false);
  });
});
