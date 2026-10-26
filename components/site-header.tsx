import Link from "next/link";

const studentLinks = [
  { href: "/pyq", label: "PYQs" },
  { href: "/chapterwise", label: "Chapters" },
  { href: "/mock-tests", label: "Mock tests" },
  { href: "/challenge", label: "Daily challenge" },
];

export function SiteHeader({ variant = "student" }: { variant?: "student" | "admin" }) {
  const isAdmin = variant === "admin";
  const links = isAdmin
    ? [
        { href: "/admin", label: "Challenges" },
        { href: "/admin/pyq", label: "PYQ workbench" },
        { href: "/pyq", label: "Student view" },
      ]
    : studentLinks;

  return (
    <header className="mb-8 border-b border-[var(--border)] pb-4">
      <div className="flex min-h-12 items-center justify-between gap-4">
        <Link
          href={isAdmin ? "/admin" : "/"}
          aria-label={isAdmin ? "BLACK-JEE admin" : "BLACK-JEE home"}
          className="flex shrink-0 items-center gap-3"
        >
          <span className="grid size-9 place-items-center rounded-xl bg-[var(--accent)] text-xs font-black text-[var(--accent-foreground)]">
            BJ
          </span>
          <span className="text-sm font-extrabold tracking-[0.15em]">
            {isAdmin ? "BLACK-JEE ADMIN" : "BLACK-JEE"}
          </span>
        </Link>
        <div className="hidden items-center gap-2 sm:flex">
          {links.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-lg px-3 py-2 text-sm text-[var(--muted-strong)] transition-colors hover:bg-white/[0.04] hover:text-[var(--accent)]"
            >
              {item.label}
            </Link>
          ))}
        </div>
        <Link
          href={isAdmin ? "/" : "/profile"}
          className="inline-flex min-h-9 items-center rounded-lg border border-[var(--border-strong)] px-3 text-xs font-semibold text-[var(--muted-strong)] transition-colors hover:border-[var(--accent)] hover:text-[var(--accent)]"
        >
          {isAdmin ? "Student site ↗" : "My profile"}
        </Link>
      </div>
      <nav
        aria-label={isAdmin ? "Admin navigation" : "Practice navigation"}
        className="-mb-1 mt-3 flex gap-2 overflow-x-auto pb-1 sm:hidden"
      >
        {links.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="shrink-0 rounded-lg border border-[var(--border)] px-3 py-2 text-xs font-medium text-[var(--muted-strong)] hover:border-[var(--border-strong)] hover:text-white"
          >
            {item.label}
          </Link>
        ))}
      </nav>
    </header>
  );
}
