import type { Metadata } from "next";
import PyqLibraryContent from "@/components/pyq/pyq-library-content";

export const metadata: Metadata = { title: "Previous-year questions" };

export default function PyqPage() {
  return <PyqLibraryContent />;
}
