import { z } from "zod";

const optionSchema = z
  .array(
    z.object({
      id: z.string().trim().min(1).max(20),
      label: z.string().trim().min(1).max(12),
      text: z.string().max(4000).default(""),
      imagePath: z.string().trim().max(500).optional(),
    }),
  )
  .max(12);

export const questionSchema = z.object({
  questionId: z.string().uuid().nullable(),
  sourceId: z.string().trim().max(160),
  title: z.string().trim().min(3).max(240),
  exam: z.string().trim().max(80),
  year: z.number().int().min(2000).max(2100).nullable(),
  session: z.string().trim().max(120),
  subject: z.enum(["Physics", "Chemistry", "Mathematics"]),
  chapter: z.string().trim().max(160),
  statement: z.string().trim().min(1).max(100000),
  statementImagePath: z.string().trim().max(500),
  options: optionSchema,
  questionType: z.enum(["single_correct", "numerical"]),
  marksCorrect: z.number().int().min(1).max(20),
  marksWrong: z.number().int().min(-20).max(0),
  correctAnswer: z.string().trim().min(1).max(100),
  solution: z.string().max(100000),
  sourcePdf: z.string().trim().max(500),
  sourcePage: z.number().int().min(1).max(10000).nullable(),
  tags: z.array(z.string().trim().min(1).max(80)).max(30),
  assetPaths: z.array(z.string().trim().min(1).max(500)).max(100),
  reviewNotes: z.array(z.string().trim().min(1).max(1000)).max(30).optional(),
}).superRefine((question, context) => {
  if (question.questionType === "single_correct" && question.options.length < 2) {
    context.addIssue({
      code: "custom",
      path: ["options"],
      message: "Single-correct questions need at least two options.",
    });
  }
});
