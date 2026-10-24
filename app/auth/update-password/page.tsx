import type { Metadata } from "next";
import { UpdatePasswordForm } from "@/components/auth/update-password-form";

export const metadata: Metadata = { title: "Choose a new password" };

export default function UpdatePasswordPage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-lg flex-col justify-center px-5 py-12">
      <a href="/" className="mb-8 text-sm font-bold tracking-[0.18em]">BLACK-JEE</a>
      <section className="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-6 sm:p-8">
        <h1 className="text-3xl font-semibold tracking-tight">Choose a new password</h1>
        <p className="mt-3 text-sm leading-6 text-[var(--muted)]">Open this page from the password reset link sent to your email.</p>
        <div className="mt-7"><UpdatePasswordForm /></div>
      </section>
    </main>
  );
}
