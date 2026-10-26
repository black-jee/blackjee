import type { Metadata } from "next";
import ChapterPracticeContent from "@/components/chapter-practice/chapter-practice-content";

export const metadata: Metadata = { title: "Chapter practice" };

export default function ChapterPracticePage() {
  return <ChapterPracticeContent />;
}
