#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# split-chapters.sh — Build each chapter as a separate PDF
#
# Usage:  ./scripts/split-chapters.sh [chapter_number]
#   No argument  → builds ALL chapters
#   With number  → builds only that chapter (e.g. ./scripts/split-chapters.sh 5)
#
# Output: build/chapters/ch01-introduction.pdf, ch02-literature-review.pdf, ...
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="src"
BUILD_DIR="build/chapters"

mkdir -p "$BUILD_DIR"

# ── Discover chapter files from main.tex ─────────────────────────────────────
mapfile -t CHAPTERS < <(
  grep -oP '\\input\{chapters/\Kch\d+-[^}]+' "$SRC_DIR/main.tex"
)

if [ ${#CHAPTERS[@]} -eq 0 ]; then
  echo "Error: no chapters found in $SRC_DIR/main.tex"
  exit 1
fi

# ── Filter to a single chapter if argument given ─────────────────────────────
FILTER="${1:-}"
if [ -n "$FILTER" ]; then
  FILTERED=()
  for ch in "${CHAPTERS[@]}"; do
    num=$(echo "$ch" | grep -oP '\d+' | head -1 | sed 's/^0*//')
    if [ "$num" = "$FILTER" ]; then
      FILTERED+=("$ch")
    fi
  done
  if [ ${#FILTERED[@]} -eq 0 ]; then
    echo "Error: no chapter matching number '$FILTER' found."
    echo "Available chapters:"
    for ch in "${CHAPTERS[@]}"; do echo "  $ch"; done
    exit 1
  fi
  CHAPTERS=("${FILTERED[@]}")
fi

# ── Build each chapter ───────────────────────────────────────────────────────
TOTAL=${#CHAPTERS[@]}
PASS=0
FAIL=0

for ch in "${CHAPTERS[@]}"; do
  # Place the wrapper .tex inside src/ so \input{config} resolves correctly
  WRAPPER="$SRC_DIR/_ch-build-${ch}.tex"
  
  printf "  [%d/%d] Building %s … " "$((PASS + FAIL + 1))" "$TOTAL" "$ch"

  # Generate a standalone wrapper that loads the full preamble + single chapter
  cat > "$WRAPPER" <<'HEREDOC_END'
\documentclass[a4paper,14pt]{extreport}
\input{config}
\begin{document}
\pagenumbering{arabic}
\onehalfspacing
HEREDOC_END
  echo "\\input{chapters/${ch}}" >> "$WRAPPER"
  cat >> "$WRAPPER" <<'HEREDOC_END'
\printbibliography[heading=bibintoc, title={References}]
\end{document}
HEREDOC_END

  # Compile with output going to the chapters build dir
  if latexmk -pdf -f -shell-escape -interaction=nonstopmode \
       -output-directory="../$BUILD_DIR" \
       -cd "$WRAPPER" > /dev/null 2>&1; then
    # Rename from wrapper name to chapter name
    mv "$BUILD_DIR/_ch-build-${ch}.pdf" "$BUILD_DIR/${ch}.pdf" 2>/dev/null || true
    echo "✓"
    PASS=$((PASS + 1))
  else
    echo "✗ (see $BUILD_DIR/_ch-build-${ch}.log)"
    FAIL=$((FAIL + 1))
  fi

  # Always clean up the wrapper .tex from src/
  rm -f "$WRAPPER"
done

# ── Cleanup auxiliary files from the build dir ───────────────────────────────
rm -f "$BUILD_DIR"/_ch-build-*.{aux,bbl,bcf,blg,fdb_latexmk,fls,log,out,run.xml,toc,lof,lot,pyg} 2>/dev/null || true

echo ""
echo "==== Chapter PDFs: $PASS passed, $FAIL failed → $BUILD_DIR/"
