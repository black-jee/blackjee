import Link from "next/link";
const modules = [
  {
    number: "01",
    title: "Daily challenge",
    description: "A focused attempt with server-enforced timing and results release.",
    status: "In progress",
  },
  {
    number: "02",
    title: "Previous-year questions",
    description: "Browse exam questions with reviewed solutions, diagrams and formulas.",
    status: "In progress",
  },
  {
    number: "03",
    title: "Chapter practice",
    description: "Build accuracy topic by topic with protected answer feedback.",
    status: "Migration queued",
  },
  {
    number: "04",
    title: "Mock tests",
    description: "Practice in a responsive computer-based test experience.",
    status: "Migration queued",
  },
];

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-screen w-full max-w-7xl flex-col px-5 py-6 sm:px-8 lg:px-12">
      <header className="flex items-center justify-between border-b border-[var(--border)] pb-5">
        <Link href="/" aria-label="BLACK-JEE home" className="flex items-center gap-3">
          <span className="grid size-10 place-items-center rounded-xl bg-[var(--accent)] text-sm font-black tracking-tight text-[var(--accent-foreground)]">
            BJ
          </span>
          <span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE</span>
        </Link>
        <nav
          aria-label="Main navigation"
          className="flex items-center gap-4 text-xs text-[var(--muted)] sm:gap-5"
        >
          <a href="/challenge" className="hover:text-[var(--text)]">
            Challenge
          </a>
          <a href="/pyq" className="hover:text-[var(--text)]">
            PYQs
          </a>
          <a href="/chapterwise" className="hover:text-[var(--text)]">
            Chapters
          </a>
          <a href="/mock-tests" className="hover:text-[var(--text)]">
            Mock tests
          </a>
          <a href="/profile" className="hover:text-[var(--text)]">
            Profile
          </a>
          <a href="/admin" className="hover:text-[var(--text)]">
            Admin
          </a>
          <a
            href="/login"
            className="rounded-full border border-[var(--border)] px-3 py-1.5 hover:text-[var(--text)]"
          >
            Sign in
          </a>
        </nav>
      </header>

      <section className="grid flex-1 content-center gap-10 py-16 lg:grid-cols-[1.1fr_0.9fr] lg:items-center lg:gap-16 lg:py-24">
        <div>
          <p className="mb-5 text-xs font-bold uppercase tracking-[0.24em] text-[var(--accent)]">
            Prepare with purpose
          </p>
          <h1 className="max-w-3xl text-5xl font-semibold leading-[1.02] tracking-[-0.055em] sm:text-6xl lg:text-7xl">
            Every question is a chance to get sharper.
          </h1>
          <p className="mt-6 max-w-xl text-base leading-7 text-[var(--muted)] sm:text-lg">
            BLACK-JEE is being rebuilt around the original student and admin workflows, with safer
            question delivery, reliable attempts, and a consistent practice experience.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href="/challenge"
              className="rounded-xl bg-[#6366f1] px-5 py-3 text-sm font-bold text-white shadow-lg shadow-indigo-950/30 transition-all duration-200 hover:-translate-y-0.5 hover:bg-[#4f46e5] hover:shadow-indigo-900/40 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-indigo-300"
            >
              Open daily challenge <span aria-hidden="true">↗</span>
            </a>
            <a
              href="/login"
              className="rounded-xl border border-[var(--border)] px-5 py-3 text-sm font-semibold text-[var(--text)] hover:bg-white/5"
            >
              Sign in
            </a>
          </div>
        </div>

        <aside className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-7">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-semibold">Rebuild status</p>
              <p className="mt-1 text-xs text-[var(--muted)]">
                Source audit → foundation → feature migration
              </p>
            </div>
            <span
              className="size-2.5 rounded-full bg-[var(--accent)] shadow-[0_0_18px_var(--accent)]"
              aria-label="In progress"
            />
          </div>
          <div className="mt-7 space-y-4">
            {[
              ["Source archive", "84 files inspected", true],
              ["Target backend", "Project reachable; security review open", true],
              ["Feature migration", "In progress", false],
              ["Staging verification", "Not started", false],
            ].map(([label, detail, done]) => (
              <div key={label as string} className="flex gap-3">
                <span
                  className={`mt-0.5 grid size-5 shrink-0 place-items-center rounded-full border text-[10px] ${done ? "border-[var(--accent)] bg-[var(--accent)] text-[var(--accent-foreground)]" : "border-[var(--border)] text-[var(--muted)]"}`}
                  aria-hidden="true"
                >
                  {done ? "✓" : "·"}
                </span>
                <div>
                  <p className="text-sm font-medium">{label}</p>
                  <p className="mt-1 text-xs leading-5 text-[var(--muted)]">{detail}</p>
                </div>
              </div>
            ))}
          </div>
          <p className="mt-7 border-t border-[var(--border)] pt-4 text-xs leading-5 text-[var(--muted)]">
            This is the engineering foundation, not a claim that the legacy workflows are already
            migrated or production-ready.
          </p>
        </aside>
      </section>

      <section id="modules" className="pb-16">
        <div className="mb-6 flex items-end justify-between gap-4">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--muted)]">
              Platform map
            </p>
            <h2 className="mt-2 text-2xl font-semibold tracking-tight sm:text-3xl">
              Built around how students practice
            </h2>
          </div>
          <span className="hidden text-xs text-[var(--muted)] sm:block">
            01 — 04 / Core modules
          </span>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          {modules.map((module) => (
            <article
              key={module.number}
              className="group rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 transition-colors hover:bg-[var(--surface-raised)] sm:p-6"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold tracking-[0.18em] text-[var(--accent)]">
                  {module.number}
                </span>
                <span className="rounded-full border border-[var(--border)] px-2.5 py-1 text-[10px] text-[var(--muted)]">
                  {module.status}
                </span>
              </div>
              <h3 className="mt-5 text-lg font-semibold">{module.title}</h3>
              <p className="mt-2 max-w-md text-sm leading-6 text-[var(--muted)]">
                {module.description}
              </p>
            </article>
          ))}
        </div>
      </section>

      <footer className="flex flex-col gap-2 border-t border-[var(--border)] py-5 text-xs text-[var(--muted)] sm:flex-row sm:items-center sm:justify-between">
        <span>BLACK-JEE · Rebuild in progress</span>
        <span>Original production site remains untouched.</span>
      </footer>
    </main>
  );
}
