#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# preview.sh — Build and copy a preview PDF to output/
#
# Usage:
#   ./scripts/preview.sh             → output/<slug>-preview1.pdf (auto-increments)
#   ./scripts/preview.sh "My Draft"  → output/my-draft-preview1.pdf (auto-increments)
#   make preview                     → same as no-arg form
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${PROJECT_DIR}/src"
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${PROJECT_DIR}/output"
YML="${SRC_DIR}/project.yml"
PDF="${BUILD_DIR}/main.pdf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# ── Read metadata from project.yml ──────────────────────────────────────────
yaml_get() {
  grep "^${1}:" "$YML" | head -1 | sed "s/^${1}:[[:space:]]*//" | sed 's/^"//;s/"$//'
}

BOOK_TITLE=$(yaml_get "book_title")

if [[ -z "$BOOK_TITLE" ]]; then
  echo -e "${RED}Error: book_title not found in project.yml${NC}"
  exit 1
fi

# ── Determine base name ──────────────────────────────────────────────────────
# If a name is passed as $1, use it; otherwise fall back to the book title slug.
if [[ $# -ge 1 && -n "$1" ]]; then
  BASE_SLUG=$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
else
  BASE_SLUG=$(echo "$BOOK_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
fi

# ── Auto-increment preview number ───────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"

NEXT_NUM=1
while [[ -f "${OUTPUT_DIR}/${BASE_SLUG}-preview${NEXT_NUM}.pdf" ]]; do
  (( NEXT_NUM++ ))
done

FILENAME="${BASE_SLUG}-preview${NEXT_NUM}.pdf"
DATE=$(date +%Y-%m-%d)

echo -e "${BOLD}─── Preview Build ───${NC}"
echo ""
echo "  Base:    ${BASE_SLUG}"
echo "  Preview: #${NEXT_NUM}"
echo "  File:    ${FILENAME}"
echo ""

# ── Step 1: Build ────────────────────────────────────────────────────────────
echo -e "${BOLD}[1/3] Building PDF...${NC}"
cd "$PROJECT_DIR"
make build > /dev/null 2>&1
echo "  Done."

# ── Step 2: Compress ─────────────────────────────────────────────────────────
echo -e "${BOLD}[2/3] Compressing...${NC}"
BEFORE=$(du -h "$PDF" | cut -f1)

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
   -dPDFSETTINGS=/prepress -dNOPAUSE -dBATCH -dQUIET \
   -sOutputFile="${BUILD_DIR}/main-compressed.pdf" \
   "$PDF"

mv "${BUILD_DIR}/main-compressed.pdf" "$PDF"
AFTER=$(du -h "$PDF" | cut -f1)
echo "  ${BEFORE} → ${AFTER}"

# ── Step 3: Copy to output/ ──────────────────────────────────────────────────
echo -e "${BOLD}[3/3] Copying preview...${NC}"
cp "$PDF" "${OUTPUT_DIR}/${FILENAME}"

# Update the latest-preview symlink
ln -sf "$FILENAME" "${OUTPUT_DIR}/latest-preview.pdf"

echo ""
echo -e "${YELLOW}${BOLD}==== Preview ready: output/${FILENAME}${NC}"
echo -e "${YELLOW}       Symlink: output/latest-preview.pdf → ${FILENAME}${NC}"
echo ""
echo "  Date:    ${DATE}"
echo "  Preview: #${NEXT_NUM}"
echo "  Size:    ${AFTER}"
