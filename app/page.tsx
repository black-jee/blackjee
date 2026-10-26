import Link from "next/link";

const subjects = [
  {
    name: "Physics",
    mark: "PH",
    detail: "Concepts, laws and problem solving",
    href: "/pyq?subject=Physics",
  },
  {
    name: "Chemistry",
    mark: "CH",
    detail: "Physical, organic and inorganic",
    href: "/pyq?subject=Chemistry",
  },
  {
    name: "Mathematics",
    mark: "MA",
    detail: "Build speed through practice",
    href: "/pyq?subject=Mathematics",
  },
];

const modules = [
  {
    number: "01",
    title: "Previous-year questions",
    description: "Practice published JEE questions with source context and reviewed content.",
    href: "/pyq",
    action: "Explore PYQs",
    featured: true,
  },
  {
    number: "02",
    title: "Daily challenge",
    description: "Take on a focused challenge and review your attempt when results are released.",
    href: "/challenge",
    action: "View challenge",
    featured: false,
  },
  {
    number: "03",
    title: "Chapter practice",
    description: "Find questions by subject and chapter to focus on a topic.",
    href: "/chapterwise",
    action: "Browse chapters",
    featured: false,
  },
  {
    number: "04",
    title: "Mock tests",
    description: "Prepare with a timed, computer-based test experience.",
    href: "/mock-tests",
    action: "View mock tests",
    featured: false,
  },
];

export default function HomePage() {
  return (
    <main className="mx-auto min-h-screen w-full max-w-[1440px] px-4 sm:px-7 lg:px-12">
      <header className="flex min-h-[76px] items-center justify-between gap-4 border-b border-[var(--border)]">
        <Link href="/" aria-label="BLACK-JEE home" className="flex shrink-0 items-center gap-3">
          <span className="grid size-10 place-items-center rounded-xl bg-[var(--accent)] text-sm font-black tracking-tight text-[var(--accent-foreground)]">
            BJ
          </span>
          <span className="text-sm font-extrabold tracking-[0.16em]">BLACK-JEE</span>
        </Link>
        <nav
          aria-label="Main navigation"
          className="hidden items-center gap-6 text-sm text-[var(--muted-strong)] md:flex"
        >
          <Link href="/pyq" className="transition-colors hover:text-[var(--accent)]">
            PYQs
          </Link>
          <Link href="/chapterwise" className="transition-colors hover:text-[var(--accent)]">
            Chapters
          </Link>
          <Link href="/mock-tests" className="transition-colors hover:text-[var(--accent)]">
            Mock tests
          </Link>
          <Link href="/challenge" className="transition-colors hover:text-[var(--accent)]">
            Daily challenge
          </Link>
        </nav>
        <div className="flex shrink-0 items-center gap-2">
          <Link
            href="/profile"
            className="hidden rounded-xl px-3 py-2 text-sm text-[var(--muted-strong)] transition-colors hover:bg-white/5 hover:text-white sm:inline-flex"
          >
            Profile
          </Link>
          <Link
            href="/login"
            className="inline-flex min-h-10 items-center justify-center rounded-xl bg-[var(--accent)] px-4 text-sm font-bold text-[var(--accent-foreground)] transition-transform hover:-translate-y-0.5"
          >
            Sign in{" "}
            <span className="ml-2" aria-hidden="true">
              ↗
            </span>
          </Link>
        </div>
      </header>

      <section className="grid gap-10 pb-14 pt-14 sm:pb-20 sm:pt-20 lg:grid-cols-[1.15fr_0.85fr] lg:items-center lg:gap-16 lg:pb-24 lg:pt-24">
        <div>
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[var(--border-strong)] bg-white/[0.025] px-3 py-1.5 text-xs font-medium text-[var(--muted-strong)]">
            <span className="size-1.5 rounded-full bg-[var(--accent)]" />
            Built for focused JEE preparation
          </div>
          <h1 className="max-w-3xl text-[clamp(2.8rem,7vw,5.7rem)] font-semibold leading-[0.98] tracking-[-0.065em]">
            Put in the work.
            <span className="mt-2 block text-[var(--accent)]">Know your edge.</span>
          </h1>
          <p className="mt-7 max-w-xl text-base leading-7 text-[var(--muted)] sm:text-lg sm:leading-8">
            A focused space for JEE practice. Work through previous-year questions, strengthen
            chapters and prepare for the pressure of the real exam.
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <Link
              href="/pyq"
              className="inline-flex min-h-12 items-center justify-center rounded-xl bg-[var(--accent)] px-5 text-sm font-bold text-[var(--accent-foreground)] transition-transform hover:-translate-y-0.5"
            >
              Start PYQ practice{" "}
              <span className="ml-2" aria-hidden="true">
                ↗
              </span>
            </Link>
            <Link
              href="/mock-tests"
              className="inline-flex min-h-12 items-center justify-center rounded-xl border border-[var(--border-strong)] bg-white/[0.02] px-5 text-sm font-semibold text-[var(--text)] transition-colors hover:bg-white/[0.06]"
            >
              Explore mock tests
            </Link>
          </div>
          <div className="mt-9 flex flex-wrap gap-x-6 gap-y-2 text-xs text-[var(--muted)]">
            <span className="inline-flex items-center gap-2">
              <span className="text-[var(--accent)]">✓</span> Subject-focused practice
            </span>
            <span className="inline-flex items-center gap-2">
              <span className="text-[var(--accent)]">✓</span> Timed test experience
            </span>
            <span className="inline-flex items-center gap-2">
              <span className="text-[var(--accent)]">✓</span> Review your progress
            </span>
          </div>
        </div>

        <aside
          aria-label="Quick start"
          className="relative overflow-hidden rounded-[28px] border border-[var(--border)] bg-[linear-gradient(145deg,#171a1c,#101214_70%)] p-5 sm:p-7"
        >
          <div
            aria-hidden="true"
            className="absolute -right-16 -top-20 size-56 rounded-full border border-[var(--accent)]/10"
          />
          <div
            aria-hidden="true"
            className="absolute -right-7 -top-11 size-36 rounded-full border border-[var(--accent)]/10"
          />
          <div className="relative">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">
                  Your next session
                </p>
                <h2 className="mt-3 text-2xl font-semibold tracking-tight sm:text-3xl">
                  Choose a subject.
                </h2>
                <p className="mt-2 max-w-sm text-sm leading-6 text-[var(--muted)]">
                  Start where you need the most practice today.
                </p>
              </div>
              <span
                className="grid size-11 shrink-0 place-items-center rounded-2xl border border-[var(--border-strong)] bg-black/20 text-lg"
                aria-hidden="true"
              >
                ↗
              </span>
            </div>
            <div className="mt-7 space-y-3">
              {subjects.map((subject) => (
                <Link
                  key={subject.name}
                  href={subject.href}
                  className="group flex min-h-[76px] items-center gap-4 rounded-2xl border border-[var(--border)] bg-black/15 p-4 transition-colors hover:border-[var(--accent)]/50 hover:bg-[var(--accent)]/[0.04]"
                >
                  <span className="grid size-11 shrink-0 place-items-center rounded-xl bg-[var(--surface-raised)] text-xs font-extrabold tracking-wide text-[var(--accent)]">
                    {subject.mark}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-sm font-semibold">{subject.name}</span>
                    <span className="mt-1 block text-xs leading-5 text-[var(--muted)]">
                      {subject.detail}
                    </span>
                  </span>
                  <span
                    className="text-lg text-[var(--muted)] transition-transform group-hover:translate-x-1 group-hover:text-[var(--accent)]"
                    aria-hidden="true"
                  >
                    →
                  </span>
                </Link>
              ))}
            </div>
            <p className="mt-5 text-xs leading-5 text-[var(--muted)]">
              Only reviewed and published questions are shown in student practice.
            </p>
          </div>
        </aside>
      </section>

      <section className="border-t border-[var(--border)] py-12 sm:py-16">
        <div className="mb-7 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">
              Your preparation toolkit
            </p>
            <h2 className="mt-3 text-2xl font-semibold tracking-tight sm:text-3xl">
              Everything starts with practice.
            </h2>
          </div>
          <p className="max-w-md text-sm leading-6 text-[var(--muted)]">
            Pick a path that matches your goal. Keep your sessions focused and build consistency
            over time.
          </p>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          {modules.map((module) => (
            <Link
              key={module.number}
              href={module.href}
              className={`group rounded-2xl border p-5 transition-all hover:-translate-y-0.5 hover:border-[var(--border-strong)] sm:p-6 ${module.featured ? "border-[var(--accent)]/35 bg-[linear-gradient(135deg,rgba(214,251,101,0.07),rgba(17,19,22,0.8)_55%)]" : "border-[var(--border)] bg-[var(--surface)] hover:bg-[var(--surface-raised)]"}`}
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold tracking-[0.18em] text-[var(--accent)]">
                  {module.number}
                </span>
                <span
                  className="grid size-9 place-items-center rounded-full border border-[var(--border-strong)] text-sm text-[var(--muted-strong)] transition-colors group-hover:border-[var(--accent)] group-hover:text-[var(--accent)]"
                  aria-hidden="true"
                >
                  ↗
                </span>
              </div>
              <h3 className="mt-6 text-lg font-semibold tracking-tight">{module.title}</h3>
              <p className="mt-2 min-h-12 max-w-lg text-sm leading-6 text-[var(--muted)]">
                {module.description}
              </p>
              <span className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-[var(--muted-strong)] transition-colors group-hover:text-[var(--accent)]">
                {module.action} <span aria-hidden="true">→</span>
              </span>
            </Link>
          ))}
        </div>
      </section>

      <footer className="flex flex-col gap-3 border-t border-[var(--border)] py-6 text-xs text-[var(--muted)] sm:flex-row sm:items-center sm:justify-between">
        <Link href="/" className="font-bold tracking-[0.15em] text-[var(--muted-strong)]">
          BLACK-JEE
        </Link>
        <div className="flex flex-wrap gap-x-5 gap-y-2">
          <Link href="/profile" className="hover:text-white">
            Profile
          </Link>
          <Link href="/login" className="hover:text-white">
            Sign in
          </Link>
          <Link href="/admin" className="hover:text-white">
            Admin
          </Link>
        </div>
        <span>Train with intent.</span>
      </footer>
    </main>
  );
}
