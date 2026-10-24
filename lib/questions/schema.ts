import { z } from "zod";

export const questionOptionSchema = z.object({
  id: z.string().trim().min(1).max(40),
  label: z.string().trim().min(1).max(20),
  text: z.string().max(20_000).default(""),
  imagePath: z.string().trim().max(500).optional(),
});

export const questionContentSchema = z.object({
  sourceId: z.string().trim().min(1).max(160),
  statement: z.string().trim().min(1).max(100_000),
  statementImagePath: z.string().trim().max(500).optional(),
  options: z.array(questionOptionSchema).max(12).default([]),
  subject: z.enum(["Physics", "Chemistry", "Mathematics", "Mixed"]),
  chapter: z.string().trim().max(160).optional(),
  explanation: z.string().max(100_000).optional(),
  assetPaths: z.array(z.string().trim().min(1).max(500)).max(100).default([]),
});

export type QuestionContent = z.infer<typeof questionContentSchema>;
export type QuestionOption = z.infer<typeof questionOptionSchema>;

/** Keep content paths relative and prevent URL/path traversal in imported manifests. */
export function isSafeAssetPath(path: string): boolean {
  if (!path || path.startsWith("/") || !/^[A-Za-z0-9._/-]+$/.test(path)) return false;
  const parts = path.split("/");
  return parts.every((part) => part.length > 0 && part !== "." && part !== "..");
}
