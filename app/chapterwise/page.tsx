import type { Metadata } from "next";
import ChapterwiseContent from "@/components/chapterwise/chapterwise-content";

export const metadata: Metadata = { title: "Chapter-wise practice" };

export default function ChapterwisePage() {
  return <ChapterwiseContent />;
}
