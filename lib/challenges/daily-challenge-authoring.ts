export type DailyChallengeAuthoringInput = {
  isLive: boolean;
  solution: string;
  optionLabels: string[];
  correctAnswer: string;
};

export function validateDailyChallengeAuthoring(
  input: DailyChallengeAuthoringInput,
): string | null {
  if (input.optionLabels.length > 12) {
    return "A daily challenge can have at most 12 options.";
  }

  if (input.isLive && !input.solution.trim()) {
    return "A live challenge must include a worked solution.";
  }

  if (
    input.optionLabels.length > 0 &&
    !input.optionLabels.some(
      (label) => label.toUpperCase() === input.correctAnswer.trim().toUpperCase(),
    )
  ) {
    return "Correct answer must match one of the option labels (A, B, C…).";
  }

  return null;
}
