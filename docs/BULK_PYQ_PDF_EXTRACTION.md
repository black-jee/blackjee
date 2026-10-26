# Bulk PYQ PDF extraction (draft workflow)

The admin workbench now includes a browser-side PDF upload that extracts text from text-based PDFs and creates a reviewable JSON bundle. It is designed for fast question entry first: question statement, options, answer key, source page, and shift metadata. The browser extractor is heuristic and does not perform OCR, reliably reconstruct equations, crop diagrams, recreate reaction figures, generate explanations, or publish questions. The Python script below remains available for local extraction and richer page-level visual signals.

## Browser upload in BLACK-JEE

1. Sign in with an administrator account and open `/admin/pyq`.
2. Under **Bulk import**, choose a text-based PDF (maximum 40 MB), then set the year, subject, and session/shift.
3. If available, enter the answer key before extraction using entries such as `1:A, 2:C, 3:12`. The parser matches answers by question number.
4. Review the candidates against the source PDF. Download the JSON bundle if you want to inspect or correct it before importing.

The browser loads PDF.js from cdnjs, so an internet connection is required. The PDF text is extracted in the browser; the original PDF is not sent to that CDN. Scanned/image-only PDFs need OCR, which is not included. The current authoring schema requires an answer key to save a question, so candidates without matched answers can be exported but cannot yet be saved as drafts.

## Local Python extraction

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
- `diagramSignal`, `visualTypes`, and `visualSlots` for likely question visuals, match-the-following tables, chemical reactions/structures, circular figures, and per-option visual placeholders;
- blank `solution`, `solutionStatus: "pending"`, `reviewStatus: "draft"`, and `isPublished: false`;
- review notes when options or answer keys are missing or extraction looks uncertain.

## Important limits

- The parser reads the PDF's embedded text layer. Scanned/image-only PDFs require OCR before this script can extract text.
- PDF layouts vary. The extractor is heuristic; check question boundaries, option labels, mathematical notation, and answer mapping before importing. Visual classification is only a hint: it checks text cues and whether the question's page contains images/vector drawings. It cannot reliably tell which question or option owns a visual. Match tables, reactions, circles, graphs, circuits, geometry/ray diagrams, and molecular structures get separate slot hints when text cues match; every option gets a reviewable visual placeholder. `not_detected` does not prove there is no diagram. Always review source pages and all four options.
- Embedded answer-key parsing is best-effort and depends on a clearly labelled, text-readable answer-key section. The admin PYQ page now accepts the generated JSON bundle and saves validated records through the existing admin-only save action.
- This script only writes a local JSON file. It does not connect to Supabase, bypass admin permissions, alter database records, or publish content.
- The admin importer maps records into the existing single-question validation and save workflow. It skips records with missing question text, source IDs, or answer keys; review the extraction report and saved drafts before publishing.


## PCM notation and question formats

The JSON draft preserves extracted question and option text without trying to normalize or typeset it. It adds review hints for mathematical symbols, powers/superscripts, subscripts/indices, fractions, calculus, vectors/matrices, chemical formulae/ionic notation, reaction arrows/equilibrium, and common physical units. It also labels likely match-the-following, assertion-reason, and numerical/expression formats.

These are regex-based hints, not a guarantee of correct mathematical or chemical rendering. PDF text extraction can lose two-dimensional layout, subscripts, superscripts, stacked fractions, matrix alignment, and symbols. Compare the extracted text with the source page; visual/equation crops may be needed to preserve exact notation.
