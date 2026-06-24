#!/usr/bin/env bash
# =============================================================================
# pagecounts.sh — Print TOC with per-chapter page counts
# Usage: ./scripts/pagecounts.sh [build-dir]
#   build-dir defaults to  build/
#
# Requires: pdfinfo (poppler-utils)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${1:-$BOOK_DIR/build}"
TOC_FILE="$BUILD_DIR/main.toc"
PDF_FILE="$BUILD_DIR/main.pdf"

# ── Colours ──────────────────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[36m"
YELLOW="\033[33m"
GREEN="\033[32m"
RESET="\033[0m"

# ── Sanity checks ─────────────────────────────────────────────────────────────
if [[ ! -f "$TOC_FILE" ]]; then
  echo "Error: TOC file not found at $TOC_FILE" >&2
  echo "Run 'make build' first." >&2
  exit 1
fi

if [[ ! -f "$PDF_FILE" ]]; then
  echo "Error: PDF not found at $PDF_FILE" >&2
  exit 1
fi

if ! command -v pdfinfo &>/dev/null; then
  echo "Error: pdfinfo not found. Install poppler-utils." >&2
  exit 1
fi

# ── Total PDF pages ───────────────────────────────────────────────────────────
TOTAL_PAGES=$(pdfinfo "$PDF_FILE" | awk '/^Pages:/{print $2}')

# ── Parse .toc — collect chapter-level entries only ──────────────────────────
# Each .toc line looks like:
#   \contentsline {chapter}{\numberline {1}Title}{PAGE}{chapter.1}%
#   \contentsline {chapter}{Title (no number)}{PAGE}{chapter*.N}%
#
# We want: type (chapter), title, page number.

declare -a TITLES=()
declare -a PAGES=()
declare -a TYPES=()   # "numbered" | "unnumbered"

while IFS= read -r line; do
  # Strip Windows carriage returns
  line="${line//$'\r'/}"

  # Only process chapter-level lines
  [[ "$line" == *"\\contentsline {chapter}"* ]] || continue

  # Extract page — format: \contentsline {chapter}{TITLE}{PAGE}{LABEL}%
  page=$(echo "$line" | sed -E 's/.*\{([^{}]+)\}\{[^{}]+\}%?$/\1/')

  # Skip roman-numeral front-matter pages (i, ii, ...)
  [[ "$page" =~ ^[ivxlcdmIVXLCDM]+$ ]] && continue
  [[ "$page" =~ ^[0-9]+$ ]] || continue

  # Extract title — strip leading type group, trailing page+label groups
  raw=$(echo "$line" | sed -E 's/^\\contentsline \{chapter\}\{//; s/\}\{[0-9]+\}\{[^}]+\}%?$//')

  title=$(echo "$raw" | sed -E \
    -e 's/\\numberline \{[^}]+\} *//' \
    -e 's/\\&/\&/g' \
    -e 's/\\texttt\{([^}]+)\}/\1/g' \
    -e 's/\\[a-zA-Z]+\{([^}]*)\}/\1/g' \
    -e 's/\\[a-zA-Z]+//g' \
    -e 's/[{}]//g' \
    -e 's/^ +//; s/ +$//')

  TITLES+=("$title")
  PAGES+=("$page")
done < "$TOC_FILE"

COUNT=${#TITLES[@]}

# ── Compute per-chapter page counts ──────────────────────────────────────────
declare -a PAGE_COUNTS

for (( i=0; i<COUNT; i++ )); do
  start=${PAGES[$i]}
  if (( i + 1 < COUNT )); then
    next=${PAGES[$((i+1))]}
    page_count=$(( next - start ))
  else
    # Last entry: from its start page to total pages
    page_count=$(( TOTAL_PAGES - start + 1 ))
  fi
  PAGE_COUNTS+=("$page_count")
done

# ── Pretty-print ──────────────────────────────────────────────────────────────
WIDTH=60

printf "\n"
printf "${BOLD}${CYAN}%-${WIDTH}s  %6s  %5s${RESET}\n" "Chapter / Section" "Start" "Pages"
printf "${DIM}%s${RESET}\n" "$(printf '─%.0s' $(seq 1 $(( WIDTH + 16 ))))"

for (( i=0; i<COUNT; i++ )); do
  title="${TITLES[$i]}"
  start="${PAGES[$i]}"
  count="${PAGE_COUNTS[$i]}"

  # Numbered chapters: bold + no indent; front-matter/back-matter: dim + indent
  if [[ "$title" == "References" || "$title" == "Abstract" || "$title" == "Acknowledgments" ]]; then
    colour="${DIM}"
    indent="  "
  else
    colour="${BOLD}"
    indent=""
  fi

  printf "${colour}${YELLOW}%-${WIDTH}s${RESET}  ${GREEN}%6s${RESET}  ${BOLD}%5s${RESET}\n" \
    "${indent}${title}" "$start" "$count"
done

printf "${DIM}%s${RESET}\n" "$(printf '─%.0s' $(seq 1 $(( WIDTH + 16 ))))"
printf "${BOLD}%-${WIDTH}s  %6s  ${GREEN}%5s${RESET}\n" \
  "Total" "" "$TOTAL_PAGES"
printf "\n"
printf "${DIM}PDF: $PDF_FILE${RESET}\n\n"
