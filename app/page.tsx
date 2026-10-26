import Link from "next/link";

const modules = [
  {
    number: "01",
    eyebrow: "BUILD A DAILY HABIT",
    title: "Daily challenge",
    description: "A focused daily attempt with timed questions and results released by the server.",
    href: "/challenge",
    action: "Take today's challenge",
    accent: "from-violet-500/20 to-indigo-500/5",
    icon: "✳",
    status: "In progress",
  },
  {
    number: "02",
    eyebrow: "LEARN FROM THE EXAM",
    title: "Previous-year questions",
    description: "Practice JEE questions with reviewed solutions, formulas and diagrams where available.",
    href: "/pyq",
    action: "Explore PYQs",
    accent: "from-sky-500/20 to-cyan-500/5",
    icon: "⌕",
    status: "In progress",
  },
  {
    number: "03",
    eyebrow: "MASTER THE BASICS",
    title: "Chapter practice",
    description: "Strengthen understanding one topic at a time and build accuracy steadily.",
    href: "/chapterwise",
    action: "Browse chapters",
    accent: "from-emerald-500/15 to-teal-500/5",
    icon: "◈",
    status: "Migration queued",
  },
  {
    number: "04",
    eyebrow: "EXAM-DAY PRACTICE",
    title: "Mock tests",
    description: "Get familiar with a computer-based test flow in a responsive practice experience.",
    href: "/mock-tests",
    action: "View mock tests",
    accent: "from-amber-500/15 to-orange-500/5",
    icon: "▤",
    status: "Migration queued",
  },
];

const navigation = [
  { href: "/challenge", label: "Daily challenge" },
  { href: "/pyq", label: "PYQs" },
  { href: "/chapterwise", label: "Chapters" },
  { href: "/mock-tests", label: "Mock tests" },
];

export default function HomePage() {
  return (
    <main className="relative isolate min-h-screen overflow-hidden">
      <div aria-hidden="true" className="pointer-events-none absolute inset-x-0 top-0 -z-10 h-[620px] bg-[radial-gradient(ellipse_at_12%_0%,rgba(99,102,241,0.20),transparent_44%),radial-gradient(ellipse_at_90%_12%,rgba(14,165,233,0.12),transparent_38%)]" />

      <div className="mx-auto flex min-h-screen w-full max-w-7xl flex-col px-4 sm:px-7 lg:px-10">
        <header className="flex flex-col gap-4 border-b border-white/[0.08] py-5 sm:flex-row sm:items-center sm:justify-between">
          <Link href="/" aria-label="BLACK-JEE home" className="group flex w-fit items-center gap-3">
            <span className="grid size-10 place-items-center rounded-2xl bg-gradient-to-br from-indigo-400 to-violet-600 text-sm font-black text-white shadow-lg shadow-indigo-950/50 transition-transform group-hover:scale-105">
              BJ
            </span>
            <span className="text-sm font-extrabold tracking-[0.2em] text-white">BLACK-JEE</span>
          </Link>

          <nav aria-label="Main navigation" className="flex flex-wrap items-center gap-1 text-sm text-[var(--muted)] sm:gap-2">
            {navigation.map((item) => (
              <Link key={item.href} href={item.href} className="rounded-xl px-3 py-2 transition-colors hover:bg-white/[0.06] hover:text-white focus-visible:outline-2 focus-visible:outline-indigo-300">
                {item.label}
              </Link>
            ))}
            <Link href="/profile" className="rounded-xl px-3 py-2 transition-colors hover:bg-white/[0.06] hover:text-white focus-visible:outline-2 focus-visible:outline-indigo-300">
              Profile
            </Link>
            <Link href="/login" className="ml-0 rounded-xl border border-white/15 bg-white/[0.04] px-4 py-2 font-semibold text-white transition-all hover:border-indigo-300/50 hover:bg-indigo-400/10 sm:ml-1">
              Sign in <span aria-hidden="true">↗</span>
            </Link>
          </nav>
        </header>

        <section className="grid flex-1 items-center gap-12 py-14 sm:py-20 lg:grid-cols-[1.08fr_0.92fr] lg:gap-16 lg:py-24">
          <div className="max-w-2xl">
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-indigo-300/20 bg-indigo-400/[0.08] px-3.5 py-2 text-xs font-semibold tracking-wide text-indigo-200">
              <span className="size-1.5 rounded-full bg-indigo-300 shadow-[0_0_12px_rgba(165,180,252,0.9)]" />
              YOUR JEE PREP, WITH A PLAN
            </div>
            <h1 className="max-w-2xl text-5xl font-semibold leading-[1.02] tracking-[-0.06em] text-white sm:text-6xl lg:text-7xl">
              Practice smarter.
              <span className="mt-2 block bg-gradient-to-r from-indigo-300 via-violet-300 to-sky-300 bg-clip-text pb-2 text-transparent">
                Show up stronger.
              </span>
            </h1>
            <p className="mt-6 max-w-xl text-base leading-7 text-slate-300 sm:text-lg sm:leading-8">
              Build confidence for JEE one question at a time. Challenge yourself, revisit real exam questions, and strengthen the topics that need more practice.
            </p>
            <div className="mt-8 flex flex-col gap-3 sm:flex-row">
              <Link href="/challenge" className="group inline-flex min-h-12 items-center justify-center gap-2 rounded-xl bg-indigo-500 px-5 py-3 text-sm font-bold text-white shadow-lg shadow-indigo-950/40 transition-all duration-200 hover:-translate-y-0.5 hover:bg-indigo-400 hover:shadow-indigo-900/50 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-indigo-200">
                Open daily challenge
                <span aria-hidden="true" className="transition-transform group-hover:translate-x-0.5">↗</span>
              </Link>
              <Link href="/pyq" className="inline-flex min-h-12 items-center justify-center gap-2 rounded-xl border border-white/15 bg-white/[0.035] px-5 py-3 text-sm font-semibold text-slate-100 transition-all hover:border-white/25 hover:bg-white/[0.07] focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-indigo-200">
                Explore previous-year questions
              </Link>
            </div>
            <div className="mt-8 flex flex-wrap items-center gap-x-5 gap-y-2 text-xs text-slate-400">
              <span className="inline-flex items-center gap-2"><span className="text-emerald-300">✓</span> Practice at your pace</span>
              <span className="inline-flex items-center gap-2"><span className="text-emerald-300">✓</span> Mobile-friendly layout</span>
              <span className="inline-flex items-center gap-2"><span className="text-emerald-300">✓</span> Focus on understanding</span>
            </div>
          </div>

          <aside className="relative mx-auto w-full max-w-lg">
            <div aria-hidden="true" className="absolute -inset-5 rounded-[2rem] bg-gradient-to-br from-indigo-500/15 via-violet-500/5 to-sky-500/10 blur-2xl" />
            <div className="relative overflow-hidden rounded-[1.75rem] border border-white/10 bg-[#10131d]/90 p-5 shadow-2xl shadow-black/30 backdrop-blur sm:p-7">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-xs font-bold uppercase tracking-[0.2em] text-indigo-300">Your practice space</p>
                  <h2 className="mt-2 text-xl font-semibold text-white sm:text-2xl">Choose your next step</h2>
                  <p className="mt-2 text-sm leading-6 text-slate-400">Different ways to prepare, one goal in mind.</p>
                </div>
                <span className="grid size-11 shrink-0 place-items-center rounded-2xl border border-indigo-300/20 bg-indigo-400/10 text-xl text-indigo-200" aria-hidden="true">✦</span>
              </div>
              <div className="mt-6 space-y-3">
                {modules.slice(0, 3).map((module) => (
                  <Link key={module.number} href={module.href} className="group flex items-center gap-3 rounded-2xl border border-white/[0.07] bg-white/[0.025] p-3.5 transition-all hover:border-indigo-300/25 hover:bg-white/[0.055] focus-visible:outline-2 focus-visible:outline-indigo-300 sm:p-4">
                    <span className={`grid size-11 shrink-0 place-items-center rounded-xl bg-gradient-to-br ${module.accent} text-lg text-white`} aria-hidden="true">{module.icon}</span>
                    <span className="min-w-0 flex-1">
                      <span className="block text-sm font-semibold text-slate-100">{module.title}</span>
                      <span className="mt-1 block text-xs leading-5 text-slate-400">{module.eyebrow}</span>
                    </span>
                    <span className="text-lg text-slate-500 transition-transform group-hover:translate-x-1 group-hover:text-indigo-200" aria-hidden="true">→</span>
                  </Link>
                ))}
              </div>
              <div className="mt-5 flex items-center gap-3 rounded-xl border border-white/[0.06] bg-black/20 px-4 py-3">
                <span className="grid size-8 place-items-center rounded-lg bg-emerald-400/10 text-sm text-emerald-300" aria-hidden="true">✓</span>
                <p className="text-xs leading-5 text-slate-400">A steady routine beats a rushed last-minute sprint.</p>
              </div>
            </div>
          </aside>
        </section>

        <section id="practice-options" className="pb-16 sm:pb-20">
          <div className="mb-7 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-xs font-bold uppercase tracking-[0.22em] text-indigo-300">Explore the platform</p>
              <h2 className="mt-2 text-2xl font-semibold tracking-tight text-white sm:text-3xl">Find the practice that fits today</h2>
              <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-400">Start with a quick challenge or go deeper into a topic. Choose what helps you move forward.</p>
            </div>
            <span className="text-xs text-slate-500">FOUR WAYS TO PRACTICE</span>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            {modules.map((module) => (
              <article key={module.number} className="group relative overflow-hidden rounded-2xl border border-white/[0.09] bg-[#10131b] p-5 transition-all duration-200 hover:-translate-y-1 hover:border-white/20 hover:bg-[#141824] sm:p-6">
                <div aria-hidden="true" className={`pointer-events-none absolute inset-x-0 top-0 h-24 bg-gradient-to-b ${module.accent} opacity-70`} />
                <div className="relative">
                  <div className="flex items-center justify-between gap-3">
                    <span className="grid size-10 place-items-center rounded-xl border border-white/10 bg-white/[0.045] text-lg text-white">{module.icon}</span>
                    <span className="rounded-full border border-white/10 bg-black/20 px-2.5 py-1 text-[10px] font-medium text-slate-400">{module.status}</span>
                  </div>
                  <p className="mt-5 text-[10px] font-bold tracking-[0.2em] text-slate-500">{module.eyebrow}</p>
                  <h3 className="mt-2 text-xl font-semibold text-white">{module.title}</h3>
                  <p className="mt-2 min-h-[3rem] max-w-md text-sm leading-6 text-slate-400">{module.description}</p>
                  <Link href={module.href} className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-indigo-300 transition-colors hover:text-indigo-200 focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-indigo-200">
                    {module.action} <span aria-hidden="true" className="transition-transform group-hover:translate-x-1">→</span>
                  </Link>
                </div>
              </article>
            ))}
          </div>
        </section>

        <footer className="flex flex-col gap-3 border-t border-white/[0.08] py-6 text-xs text-slate-500 sm:flex-row sm:items-center sm:justify-between">
          <Link href="/" className="w-fit font-bold tracking-[0.18em] text-slate-300">BLACK-JEE</Link>
          <span>Built for consistent practice, one session at a time.</span>
          <div className="flex flex-wrap gap-4">
            <Link href="/profile" className="transition-colors hover:text-white">Profile</Link>
            <Link href="/login" className="transition-colors hover:text-white">Sign in</Link>
            <Link href="/admin" className="transition-colors hover:text-white">Admin</Link>
          </div>
        </footer>
      </div>
    </main>
  );
}
