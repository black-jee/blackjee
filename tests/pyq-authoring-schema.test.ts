import { describe, expect, it } from "vitest";
import { questionSchema } from "../lib/questions/pyq-authoring-schema";

const baseQuestion = {
  questionId: null,
  sourceId: "BJ-TEST-001",
  title: "Sample JEE question",
  exam: "JEE Main",
  year: 2026,
  session: "April Shift 1",
  subject: "Physics" as const,
  chapter: "Mechanics",
  statement: "A body moves with constant velocity.",
  statementImagePath: "",
  options: [],
  questionType: "numerical" as const,
  marksCorrect: 4,
  marksWrong: -1,
  correctAnswer: "12.5",
  solution: "Use the stated relation.",
  sourcePdf: "paper.pdf",
  sourcePage: 1,
  tags: ["kinematics"],
  assetPaths: [],
};

describe("PYQ authoring schema", () => {
  it("accepts a numerical question without multiple-choice options", () => {
    expect(questionSchema.safeParse(baseQuestion).success).toBe(true);
  });

  it("requires at least two options for single-correct questions", () => {
    const result = questionSchema.safeParse({
      ...baseQuestion,
      questionType: "single_correct",
      correctAnswer: "A",
      options: [],
    });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues.some((issue) => issue.path.includes("options"))).toBe(true);
    }
  });

  it("accepts a single-correct question when the option set is present", () => {
    const result = questionSchema.safeParse({
      ...baseQuestion,
      questionType: "single_correct",
      correctAnswer: "A",
      options: [
        { id: "a", label: "A", text: "First option" },
        { id: "b", label: "B", text: "Second option" },
      ],
    });

    expect(result.success).toBe(true);
  });
});
