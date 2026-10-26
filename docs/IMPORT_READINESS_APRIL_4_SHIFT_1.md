# JEE Main 2026 — 4 April Shift 1 Import Readiness

## Decision

**Source acquisition is now unblocked; verified import and publication remain blocked.** The official NTA question-paper PDF has been located, alongside two useful third-party cross-check sources. A previously archived BLACK-JEE staging ZIP is also available in the project working library and contains a 75-slot manifest with question text, options, answer/solution fields, source references, and review flags. That staged data is not yet in the current repository branch and must not be treated as release-ready.

## Sources

- **Official NTA question-paper PDF:** https://cdnbbsr.s3waas.gov.in/s3f8e59f4b2fe7c5705bf878bbd494ccdf/uploads/2026/04/202604091916616339.pdf
- **Official NTA JEE Main site / question-paper listings:** https://jeemain.nta.nic.in/sitemap/
- **Official NTA Session-I final answer keys page:** https://jeemain.nta.nic.in/document/final-answer-keys-of-jeemain-2026-session-i-paper-i-b-e-b-tech/
- Third-party worked-solutions PDF: https://static.zollege.in/public/image/JEE_Mains_2026_April_4_Shift_1_Question_paper_with_Solutions_30d076fa40189dad6ca3185f7ff72379.pdf
- Third-party online question bank: https://hive.pracbee.com/jee-main/papers/jee-main-2026-online-4th-april-morning-shift
- Independent shift analysis reporting one dropped question: https://lumineet.com/past-papers/jee-main/2026/apr-04-shift-1

The NTA-hosted PDF identifies the paper as “B Tech 4th Apr 2026 Shift 1.” It exposes the official question IDs and answer-option IDs; use it as the authoritative source for paper identity, ordering, and source IDs. Use the NTA final key for official answer verification where the necessary question/option ID mapping is available. The third-party sources are helpful for reading full question text and worked explanations, but must not override the official key without a documented reason.

## Staging inventory recovered

The archived workbench ZIP contains a `shift-manifest.json` with 75 slots: 25 Physics, 25 Chemistry, and 25 Mathematics. Its current status counts are:

- 47 marked `content_added`.
- 28 marked `needs_review`.
- One question (Chemistry Q64) has no answer recorded and remains blocked.
- 19 image files are mapped to 15 question IDs, including 4 option images.
- Complete question crops: 0.
- Source-fidelity-verified visual questions: 0.
- Student-render-verified visual questions: 0.

Known review issues include Physics Q38, Chemistry Q64, Chemistry Q72, Mathematics Q19, and several answer/solution derivations. Some later audit notes report that Mathematics Q19 and Chemistry Q72 have had their calculations/content improved, but they remain held for rendering and official-key confirmation. Preserve the exact latest per-question manifest state rather than relying only on older audit summaries.

The staging manifest is not yet in the inspected current repository tree. The archived ZIP's asset files are not currently verified against the official NTA paper or the student UI. Do not infer that a question is ready merely because its status is `content_added`.

## Count and dropped-question handling

The NTA paper is structured with 75 slots (25 per subject), while a third-party analysis reports 74 countable questions because one was dropped by NTA. Preserve the original NTA question ID/number and record the official dropped-question or scoring treatment from the final key. Do not silently delete or renumber a slot to force a 74- or 75-question count.

## Required before import/publication

1. Reconcile every question stem, option, original NTA question ID, answer, and solution against the official NTA PDF and final key; cross-check text against Zollege/PracBee where useful.
2. Verify the dropped-question/bonus treatment and capture it as explicit metadata.
3. Resolve the full `needs_review` queue and independently validate answer-key mappings and calculations.
4. Match every diagram and option image to the official source; verify image fidelity and student-page rendering on mobile and desktop.
5. Prepare an idempotent import manifest with stable source IDs, subject, original question number, question type, options, source page/question ID, review status, and dropped-question status.
6. Import only as unpublished drafts. Store answer keys and solutions in the private schema; do not expose them in public JSON, logs, or public repo artifacts.
7. Test anonymous, ordinary authenticated, and administrator access to ensure draft content and private answer keys are inaccessible to unauthorized users.
8. Reconcile row counts, run a dry-run first, and rerun database security tests before any publication decision.

## Current database safety boundary

The new Supabase project previously contained five PYQ draft records and five private answer-key records, with zero published PYQs. This documentation update does not modify the database, migrations, or publication state. Keep those unchanged until the manifest is reconciled and the draft-only import has passed a dry-run and access-control checks.
