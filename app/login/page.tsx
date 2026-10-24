import type { Metadata } from "next";
import Link from "next/link";
import { Suspense } from "react";
import { LoginForm } from "@/components/auth/login-form";

export const metadata: Metadata = { title: "Sign in" };

export default function LoginPage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-lg flex-col justify-center px-5 py-12">
      <Link href="/" className="mb-8 flex items-center gap-3">
        <span className="grid size-10 place-items-center rounded-xl bg-[var(--accent)] text-sm font-black text-[var(--accent-foreground)]">
          BJ
        </span>
        <span className="text-sm font-bold tracking-[0.18em]">BLACK-JEE</span>
      </Link>
      <div className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-6 sm:p-8">
        <p className="text-xs font-bold uppercase tracking-[0.2em] text-[var(--accent)]">
          Your practice space
        </p>
        <h1 className="mt-3 text-3xl font-semibold tracking-tight">Sign in</h1>
        <p className="mt-3 text-sm leading-6 text-[var(--muted)]">
          Use your BLACK-JEE account to start a challenge and keep your progress private.
        </p>
        <div className="mt-7">
          <Suspense fallback={<p className="text-sm text-[var(--muted)]">Loading sign-in…</p>}>
            <LoginForm />
          </Suspense>
        </div>
      </div>
      <p className="mt-5 text-center text-xs leading-5 text-[var(--muted)]">
        Sign-in availability depends on the authentication providers configured in the new Supabase
        project.
      </p>
    </main>
  );
}
