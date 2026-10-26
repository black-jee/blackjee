# Bulk PYQ PDF extraction (draft workflow)

This utility turns a locally available, text-based exam PDF into a reviewable JSON bundle. It is designed for fast question entry first: question statement, options, answer key, source page, and shift metadata. It does **not** attempt to recreate diagrams, crop reaction figures, generate explanations, or publish questions.

## Requirements

- Python 3.10+
- PyMuPDF: `python -m pip install pymupdf`
- A PDF you are authorized to process

## Run

From the repository root:

```bash
python scripts/extract-pyq-pdf.py paper.pdf \
  --year 2026 \
  --shift "4 April Shift 1" \
  --subject Physics \
  --out pyq-drafts.json
```

The extractor attempts to read a clearly labelled answer-key section from the same PDF. If that layout is not recognized or the answer key is in a separate file, provide a CSV with headers `question,answer`:

```csv
question,answer
1,B
2,D
3,A
```

Then add `--answer-key answer-key.csv`. JSON answer keys are also accepted as an object, for example `{"1":"B","2":"D"}`.

## Output contract

Each extracted candidate includes:
- exam, year, shift, subject, question number, title, source PDF and page;
- statement and detected options (where recognizable);
- correct-answer field, if a supplied answer-key file maps to that question number;
- `diagramPlaceholder` for manual diagram / graph / reaction work;
- blank `solution`, `solutionStatus: "pending"`, `reviewStatus: "draft"`, and `isPublished: false`;
- review notes when options or answer keys are missing or extraction looks uncertain.

## Important limits

- The parser reads the PDF's embedded text layer. Scanned/image-only PDFs require OCR before this script can extract text.
- PDF layouts vary. The extractor is heuristic; check question boundaries, option labels, mathematical notation, and answer mapping before importing.
- Embedded answer-key parsing is best-effort and depends on a clearly labelled, text-readable answer-key section. The admin PYQ page now accepts the generated JSON bundle and saves validated records through the existing admin-only save action.
- This script only writes a local JSON file. It does not connect to Supabase, bypass admin permissions, alter database records, or publish content.
- The admin importer maps records into the existing single-question validation and save workflow. It skips records with missing question text, source IDs, or answer keys; review the extraction report and saved drafts before publishing.
