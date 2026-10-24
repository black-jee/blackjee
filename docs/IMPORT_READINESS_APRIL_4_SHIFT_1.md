# JEE Main 2026 — 4 April Shift 1 Import Readiness

## Decision

**Do not publish or bulk-import this shift into the student-facing question bank yet.** The source archive contains a 75-slot workbench manifest, but the official source PDF is not included and the visual assets have not been verified against it or in the student UI.

## Inventory found in the supplied source archive

- Expected questions: 75 total — 25 Physics, 25 Chemistry, 25 Mathematics.
- Workbench status: 47 marked `content_added`; 28 marked `needs_review`.
- Visual assets: 19 image files mapped to 15 question IDs, including 4 answer-option images.
- Complete question crops: 0.
- Missing referenced asset files: 0.
- Source-verified visual questions: 0.
- Render-verified visual questions: 0.
- Official source PDF supplied in the archive: no.
- The manifest explicitly records unresolved content/key issues, including Physics Q38, Chemistry Q64 and Q72, and OCR corruption for Mathematics Q19. It also notes some mathematics solutions still need stronger derivations.

These counts describe the source archive's own manifests; they are not independent proof that the answers or wording are correct.

## Required before import/publication

1. Obtain the official source PDF and verify the exact paper/date/shift.
2. Reconcile all 75 question statements, options, answer keys, and solutions against the source.
3. Resolve every `needs_review` item and all explicit blockers; independently verify answer-key mappings.
4. Match every image to its source question and option, then check image and math rendering on mobile and desktop.
5. Import only as unpublished drafts with stable source IDs and source page references; keep answer keys in the private schema.
6. Run database access tests as anonymous, ordinary authenticated, and administrator roles before approving any publication.

## Current new-project state

The new Supabase project previously contained five PYQ draft records and five private answer-key records, with zero published PYQs. This readiness note does not import or publish additional records. Keep that state unchanged until the verification steps above are complete.
