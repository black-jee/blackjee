import { describe, expect, it } from "vitest";
import { validateDailyChallengeAuthoring } from "../lib/challenges/daily-challenge-authoring";

describe("daily challenge authoring validation", () => {
  it("rejects a live challenge without a worked solution", () => {
    expect(
      validateDailyChallengeAuthoring({
        isLive: true,
        solution: "   ",
        optionLabels: ["A", "B"],
        correctAnswer: "A",
      }),
    ).toBe("A live challenge must include a worked solution.");
  });

  it("allows a draft to be saved before its solution is ready", () => {
    expect(
      validateDailyChallengeAuthoring({
        isLive: false,
        solution: "",
        optionLabels: ["A", "B"],
        correctAnswer: "A",
      }),
    ).toBeNull();
  });

  it("allows numerical challenges without multiple-choice options", () => {
    expect(
      validateDailyChallengeAuthoring({
        isLive: true,
        solution: "Substitute the values into the relation.",
        optionLabels: [],
        correctAnswer: "12.5",
      }),
    ).toBeNull();
  });

  it("rejects more than twelve options instead of truncating them", () => {
    expect(
      validateDailyChallengeAuthoring({
        isLive: false,
        solution: "",
        optionLabels: Array.from({ length: 13 }, (_, index) => String.fromCharCode(65 + index)),
        correctAnswer: "A",
      }),
    ).toBe("A daily challenge can have at most 12 options.");
  });

  it("rejects a multiple-choice answer that does not match an option label", () => {
    expect(
      validateDailyChallengeAuthoring({
        isLive: false,
        solution: "",
        optionLabels: ["A", "B"],
        correctAnswer: "C",
      }),
    ).toBe("Correct answer must match one of the option labels (A, B, C…).");
  });
});
