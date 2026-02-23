#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# wordcount.sh — Count words/pages in the compiled PDF or source .tex files
# Usage: ./scripts/wordcount.sh [--tex]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${PROJECT_DIR}/src"
PDF="${PROJECT_DIR}/build/main.pdf"

if [[ "${1:-}" == "--tex" ]]; then
  echo "─── Word Count (TeX Sources) ───"
  echo ""
  TOTAL=0
  shopt -s nullglob
  for f in "${SRC_DIR}"/chapters/*.tex "${SRC_DIR}"/frontmatter/*.tex "${SRC_DIR}"/appendices/*.tex; do
    [[ -f "$f" ]] || continue
    COUNT=$(sed 's/\\[a-zA-Z]*\({[^}]*}\)*//g; s/[{}%\\]//g' "$f" | wc -w)
    BASENAME=$(basename "$f")
    printf "  %-40s %6d words\n" "$BASENAME" "$COUNT"
    TOTAL=$((TOTAL + COUNT))
  done
  shopt -u nullglob
  echo "  ────────────────────────────────────────────────"
  printf "  %-40s %6d words\n" "TOTAL" "$TOTAL"
else
  if [[ ! -f "$PDF" ]]; then
    echo "Error: PDF not found at ${PDF}"
    echo "Run 'make build' first."
    exit 1
  fi
  echo "─── Word Count (PDF) ───"
  if command -v pdftotext &>/dev/null; then
    WORDS=$(pdftotext "$PDF" - 2>/dev/null | wc -w)
    PAGES=$(pdfinfo "$PDF" 2>/dev/null | grep "^Pages:" | awk '{print $2}')
    echo "  Words: ${WORDS}"
    echo "  Pages: ${PAGES:-unknown}"
  else
    echo "  Install poppler-utils for PDF word count:"
    echo "    sudo apt install poppler-utils"
    echo ""
    echo "  Falling back to TeX source count..."
    exec "$0" --tex
  fi
fi
