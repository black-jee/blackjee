import type { Metadata } from "next";
import Link from "next/link";
import { ResetPasswordForm } from "@/components/auth/reset-password-form";

export const metadata: Metadata = { title: "Reset password" };

export default function ResetPasswordPage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-lg flex-col justify-center px-5 py-12">
      <Link href="/" className="mb-8 text-sm font-bold tracking-[0.18em]">
        BLACK-JEE
      </Link>
      <section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-6 sm:p-8">
        <h1 className="text-3xl font-semibold tracking-tight">Reset your password</h1>
        <p className="mt-3 text-sm leading-6 text-[var(--muted)]">
          Enter your account email. We will show a neutral confirmation so account existence is not
          disclosed.
        </p>
        <div className="mt-7">
          <ResetPasswordForm />
        </div>
        <a
          href="/login"
          className="mt-5 block text-center text-sm text-[var(--muted)] underline underline-offset-4"
        >
          Back to sign in
        </a>
      </section>
    </main>
  );
}
