import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "BLACK-JEE — Train with intent",
    template: "%s | BLACK-JEE",
  },
  description: "A focused JEE preparation platform for daily challenges, previous-year questions, chapter practice, and mock tests.",
  applicationName: "BLACK-JEE",
};

export const viewport: Viewport = {
  themeColor: "#08090d",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
