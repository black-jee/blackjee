#!/usr/bin/env python3
"""Extract a reviewable BLACK-JEE PYQ draft bundle from a text-based PDF.

Usage:
  python scripts/extract-pyq-pdf.py paper.pdf --year 2026 --shift "4 April Shift 1" \
    --subject Physics --answer-key answer-key.csv --out pyq-drafts.json

This is a heuristic extractor, not an OCR engine. It intentionally leaves solutions
blank and flags uncertain question boundaries/options for human review.
Requires: python -m pip install pymupdf
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path
from typing import Any

try:
    import fitz  # PyMuPDF
except ImportError:
    print("Missing dependency. Install it with: python -m pip install pymupdf", file=sys.stderr)
    raise SystemExit(2)

# Common question and option markers used in exam PDFs. Numbered options are
# normalized to BLACK-JEE labels A-D; original marker style is retained in notes.
QUESTION_START = re.compile(
    r"^\s*(?:Q(?:uestion)?\s*)?(\d{1,3})\s*[.)\]:-]\s+(.+?)\s*$",
    re.IGNORECASE,
)
OPTION_START = re.compile(
    r"^\s*(?:\(([A-D1-4])\)|([A-D])[.)]|Option\s*([A-D1-4])\s*[:.)-])\s*(.*)$",
    re.IGNORECASE,
)
def load_answer_key(path: Path | None) -> dict[str, str]:
    if path is None:
        return {}
    if path.suffix.lower() == ".json":
        raw = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(raw, dict):
            return {str(k): str(v).strip() for k, v in raw.items()}
        raise ValueError("Answer-key JSON must be an object such as { \"1\": \"B\" }.")
    answers: dict[str, str] = {}
    with path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames or not {"question", "answer"}.issubset(
            {name.strip().lower() for name in reader.fieldnames}
        ):
            raise ValueError("Answer-key CSV needs headers: question,answer")
        for row in reader:
            normalized = {str(k).strip().lower(): str(v or "").strip() for k, v in row.items()}
            if normalized.get("question") and normalized.get("answer"):
                answers[normalized["question"]] = normalized["answer"]
    return answers


def extract_text(pdf_path: Path) -> list[dict[str, Any]]:
    pages: list[dict[str, Any]] = []
    with fitz.open(pdf_path) as document:
        for page_number, page in enumerate(document, start=1):
            pages.append({"page": page_number, "text": page.get_text("text", sort=True)})
    return pages


def extract_embedded_answer_key(pages: list[dict[str, Any]]) -> dict[str, str]:
    """Best-effort parser for a clearly labelled answer-key section in the same PDF."""
    answers: dict[str, str] = {}
    in_key = False
    row_pattern = re.compile(
        r"^\s*(?:Q(?:uestion)?\s*)?(\d{1,3})\s*[.)|:-]?\s+(?:option\s*)?([A-D1-4])\b",
        re.IGNORECASE,
    )
    for page in pages:
        for raw_line in page["text"].splitlines():
            line = raw_line.strip()
            if re.search(r"(?:answer\s*key|correct\s*options?|answer\s*sheet)", line, re.I):
                in_key = True
                continue
            if not in_key:
                continue
            match = row_pattern.match(line)
            if match:
                number, answer = match.groups()
                answers[number] = {"1": "A", "2": "B", "3": "C", "4": "D"}.get(answer.upper(), answer.upper())
    return answers


def split_questions(pages: list[dict[str, Any]]) -> list[dict[str, Any]]:
    questions: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    in_answer_key = False
    for page in pages:
        for raw_line in page["text"].splitlines():
            line = raw_line.strip()
            if not line:
                continue
            if re.search(r"(?:answer\s*key|correct\s*options?|answer\s*sheet)", line, re.I):
                in_answer_key = True
                continue
            if in_answer_key:
                continue
            if re.search(r"^solutions?\b", line, re.I):
                if current is not None:
                    current["reviewNotes"].append("Solution section detected; confirm question boundary.")
                continue
            match = QUESTION_START.match(line)
            if match:
                number, first_line = match.groups()
                if current is not None:
                    questions.append(current)
                current = {
                    "questionNumber": int(number),
                    "sourcePage": page["page"],
                    "statementLines": [first_line.strip()],
                    "options": [],
                    "reviewNotes": [],
                    "optionMarkerStyle": None,
                }
                continue
            if current is None:
                continue
            option = OPTION_START.match(line)
            if option:
                marker = next((x for x in option.groups()[:3] if x), "")
                option_text = option.group(4) or ""
                label = {"1": "A", "2": "B", "3": "C", "4": "D"}.get(marker.upper(), marker.upper())
                current["options"].append({"label": label, "text": option_text.strip()})
                current["optionMarkerStyle"] = "numbered" if marker in {"1", "2", "3", "4"} else "lettered"
            elif current["options"]:
                current["options"][-1]["text"] = (current["options"][-1]["text"] + " " + line).strip()
            else:
                current["statementLines"].append(line)
    if current is not None:
        questions.append(current)

    # Keep the first occurrence of each question number; duplicates are flagged.
    seen: set[int] = set()
    unique: list[dict[str, Any]] = []
    for q in questions:
        number = q["questionNumber"]
        if number in seen:
            q["reviewNotes"].append("Duplicate question number detected; check page headers and section boundaries.")
        else:
            seen.add(number)
        q["statement"] = "\n".join(q.pop("statementLines")).strip()
        if len(q["options"]) not in (0, 4):
            q["reviewNotes"].append(f"Expected 4 options for a standard MCQ; extracted {len(q['options'])}.")
        if not q["statement"]:
            q["reviewNotes"].append("Question statement is empty.")
        q["options"] = [
            {"id": item["label"].lower(), "label": item["label"], "text": item["text"]}
            for item in q["options"]
        ]
        q["diagramPlaceholder"] = "[Add diagram / graph / reaction manually if required]"
        q["solution"] = ""
        q["solutionStatus"] = "pending"
        q["reviewStatus"] = "draft"
        q["isPublished"] = False
        unique.append(q)
    return unique


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--out", type=Path, default=Path("pyq-drafts.json"))
    parser.add_argument("--answer-key", type=Path, help="CSV (question,answer) or JSON object")
    parser.add_argument("--exam", default="JEE Main")
    parser.add_argument("--year", type=int, required=True)
    parser.add_argument("--shift", required=True, help='e.g. "4 April Shift 1"')
    parser.add_argument("--subject", choices=["Physics", "Chemistry", "Mathematics"], required=True)
    parser.add_argument("--source-url", default="")
    args = parser.parse_args()

    if not args.pdf.is_file():
        parser.error(f"PDF not found: {args.pdf}")

    try:
        pages = extract_text(args.pdf)
        answer_key = extract_embedded_answer_key(pages)
        answer_key.update(load_answer_key(args.answer_key))
        questions = split_questions(pages)
    except (ValueError, OSError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"Extraction failed: {exc}", file=sys.stderr)
        return 1

    for q in questions:
        number = str(q["questionNumber"])
        answer = answer_key.get(number, "")
        q["correctAnswer"] = answer
        if not answer:
            q["reviewNotes"].append("Answer key not matched; fill/check before import.")
        if not q["options"]:
            q["reviewNotes"].append("No options detected; likely a numerical question or a layout needing manual review.")
        q.update({
            "title": f'{args.exam} {args.year} · {args.shift} · {args.subject} Q{number}',
            "sourceId": f'BJ-{re.sub(r"[^A-Z0-9]+", "-", args.exam.upper()).strip("-")}-{args.year}-{re.sub(r"[^A-Z0-9]+", "-", args.shift.upper()).strip("-")}-{args.subject[:3].upper()}-{int(number):03d}',
            "exam": args.exam,
            "year": args.year,
            "session": args.shift,
            "subject": args.subject,
            "sourcePdf": args.pdf.name,
            "sourceUrl": args.source_url,
            "tags": ["bulk-pdf-extraction", "needs-review"],
        })

    bundle = {
        "format": "black-jee-pyq-draft-bundle",
        "version": 1,
        "sourcePdf": args.pdf.name,
        "metadata": {"exam": args.exam, "year": args.year, "shift": args.shift, "subject": args.subject},
        "extraction": {"pageCount": len(pages), "questionCount": len(questions), "engine": "PyMuPDF text layer"},
        "policy": {"solutions": "pending", "diagrams": "manual placeholder", "publish": False},
        "answerKey": {"matchedCount": sum(bool(q.get("correctAnswer")) for q in questions), "source": "sidecar overrides embedded key when supplied"},
        "questions": questions,
    }
    args.out.write_text(json.dumps(bundle, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with_options = sum(bool(q["options"]) for q in questions)
    with_answers = sum(bool(q["correctAnswer"]) for q in questions)
    flagged = sum(bool(q["reviewNotes"]) for q in questions)
    print(f"Extracted {len(questions)} question candidates from {len(pages)} pages.")
    print(f"Options detected: {with_options}; answer keys matched: {with_answers}; records flagged for review: {flagged}.")
    print(f"Wrote draft bundle: {args.out}")
    print("Nothing was uploaded to Supabase or published.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
