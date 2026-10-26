# JEE Main 2026 — 4 April Shift 1 Import Readiness

## Approved sources — only these two

1. Zollege PDF: https://static.zollege.in/public/image/JEE_Mains_2026_April_4_Shift_1_Question_paper_with_Solutions_30d076fa40189dad6ca3185f7ff72379.pdf
2. PracBee question bank: https://hive.pracbee.com/jee-main/papers/jee-main-2026-online-4th-april-morning-shift

Do not use, search for, or require any other source. Compare wording, options, answer keys, worked solutions, and visual assets between these two only. If content is missing or they disagree, flag it rather than guessing.

## Work started — source access and staging audit

- Zollege PDF opens as a 97-page document and its extracted text explicitly says the paper contains 75 compulsory questions, 25 per subject.
- PracBee currently fails to load in the available retrieval session (cache miss). Until it becomes accessible, no question can be marked as cross-checked against both approved sources.
- The archived staging manifest contains 75 slots, with 47 marked `content_added` and 28 marked `needs_review`; these labels are not evidence of source fidelity.
- A numbering/order discrepancy needs reconciliation: the archived Physics slot 1 contains a screw-gauge question mapped to paper question 26, while the Zollege PDF begins its Physics section with a soap-bubble question. Do not assume existing slot order or IDs map correctly; match each item by exact content across the two approved sources.
- The archive records 19 image files mapped to 15 question IDs, four option-image files, zero complete question crops, zero source-verified visual questions, and zero student-render-verified visual questions. These assets must not be assumed to match the Zollege diagrams until checked.
- Existing archive metadata contains references to sources outside the user's approved pair. Those references must not be used as evidence for this task; update or remove them during reconciliation.

## Required fast workflow

1. Extract the Zollege question text/options/solutions in batches, preserving source page and original question number.
2. Retry the same PracBee URL; match every question by content rather than relying on slot numbering.
3. Reuse original diagram/image assets wherever possible. Verify each diagram-bearing question against the source and its student-facing render; do not redraw or fabricate an image and call it exact.
4. Track each of the 75 slots as `verified_both_sources`, `needs_review`, or `source_unavailable`.
5. Prepare a draft-only import and validate stable IDs, 25-per-subject counts, asset paths, and private answer/solution access.

## Import and release boundary

Keep records unpublished. Keep answer keys and solutions private. Do not modify database rows, migrations, or publication state during source reconciliation. No question should be called verified until both approved sources and any required visual asset have been checked.
