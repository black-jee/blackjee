# JEE Main 2026 — 4 April Shift 1 Import Readiness

## Decision

**Source acquisition is unblocked; verified import and publication are still blocked.** Two public references have been located: a 97-page Zollege-hosted PDF titled “JEE Main 2026 April 4 Shift 1 Question Paper with Solutions” and the PracBee online question bank. The PDF describes the paper as conducted by NTA, but it is hosted by a third-party publisher, not directly on an NTA domain. Treat both as secondary working sources until checked against the official NTA question paper / final answer key where available.

- PDF: https://static.zollege.in/public/image/JEE_Mains_2026_April_4_Shift_1_Question_paper_with_Solutions_30d076fa40189dad6ca3185f7ff72379.pdf
- Online question bank: https://hive.pracbee.com/jee-main/papers/jee-main-2026-online-4th-april-morning-shift
- Independent shift analysis reporting one dropped question: https://lumineet.com/past-papers/jee-main/2026/apr-04-shift-1

## Source assessment

- Zollege PDF: usable for initial transcription and page references; contains question content and worked solutions, but OCR/text extraction and some calculations/options need independent checks.
- PracBee: useful for cross-checking question order, subject grouping, options, and proposed answers/solutions; it is also a third-party source and should not be treated as final authority.
- Count discrepancy: the first two sources describe 75 question slots (25 per subject), while an independent analysis reports 74 countable questions because one was dropped by NTA. Preserve source numbering and capture the dropped-question status explicitly after confirming it against the official final key. Do not delete/renumber a slot merely to force a 75-active-question count.
- Copyright/provenance: preserve source attribution and page/question references in internal import metadata. Do not scrape or republish a third-party solution text wholesale without confirming the project's rights and intended content policy; author/verify BLACK-JEE explanations independently where needed.

## Existing workbench inventory

The archived workbench inventory previously recorded:

- Expected slots: 75 total — 25 Physics, 25 Chemistry, 25 Mathematics.
- Workbench status: 47 marked `content_added`; 28 marked `needs_review`.
- Visual assets: 19 image files mapped to 15 question IDs, including 4 answer-option images.
- Complete question crops: 0.
- Missing referenced asset files: 0.
- Source-verified visual questions: 0.
- Render-verified visual questions: 0.
- Explicit unresolved items include Physics Q38, Chemistry Q64 and Q72, and OCR corruption for Mathematics Q19; some Mathematics solutions need stronger derivations.

These counts describe the archived workbench's own manifests; they are not independent proof that wording, images, or answers are correct. The repository branch currently contains this readiness note but no import-ready 75-question data manifest was found in the inspected repository tree.

## Required before import/publication

1. Reconcile every question, option, answer key, and solution between the PDF and online bank; record source page and online question reference.
2. Verify the official NTA final answer key and dropped-question/bonus handling, including subject and original question number.
3. Resolve all archived `needs_review` items and independently validate answer-key mappings and calculations.
4. Match each diagram/equation/image to the correct question and options; verify rendering on mobile and desktop.
5. Prepare an idempotent import manifest with stable source IDs, subject, original question number, type, options/answer where verified, solution provenance, source page, review status, and dropped-question status.
6. Import only as unpublished drafts, with answer keys in the private schema. Do not publish during ingestion.
7. Test anonymous, ordinary authenticated, and administrator access to ensure answer keys and draft content remain private.
8. Reconcile expected row counts and rerun security tests before any publication decision.

## Current database safety boundary

The new Supabase project previously contained five PYQ draft records and five private answer-key records, with zero published PYQs. This readiness update does not modify the database. Keep production data and migrations unchanged until the source manifest is reconciled, the import is reviewed, and a dry-run proves the insert/update set is safe.
