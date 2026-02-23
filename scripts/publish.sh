#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# publish.sh — Build, compress, and copy versioned PDF to output/
#
# Usage: ./scripts/publish.sh
#        make publish
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
BOLD='\033[1m'
NC='\033[0m'

# ── Read metadata from project.yml ──────────────────────────────────────────
yaml_get() {
  grep "^${1}:" "$YML" | head -1 | sed "s/^${1}:[[:space:]]*//" | sed 's/^"//;s/"$//'
}

BOOK_TITLE=$(yaml_get "book_title")
VERSION=$(yaml_get "version")
ACADEMIC_YEAR=$(yaml_get "academic_year")

if [[ -z "$BOOK_TITLE" ]]; then
  echo -e "${RED}Error: book_title not found in project.yml${NC}"
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  echo -e "${RED}Error: version not found in project.yml${NC}"
  echo "Add a 'version' field to src/project.yml, e.g.:"
  echo "  version: \"1.0.0\""
  exit 1
fi

# ── Slugify title for filename ──────────────────────────────────────────────
SLUG=$(echo "$BOOK_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
FILENAME="${SLUG}-v${VERSION}.pdf"
DATE=$(date +%Y-%m-%d)

echo -e "${BOLD}─── Publishing ───${NC}"
echo ""
echo "  Title:   ${BOOK_TITLE}"
echo "  Version: ${VERSION}"
echo "  File:    ${FILENAME}"
echo ""

# ── Step 1: Init metadata ──────────────────────────────────────────────────
echo -e "${BOLD}[1/4] Syncing metadata...${NC}"
"${PROJECT_DIR}/scripts/init.sh" > /dev/null 2>&1
echo "  Done."

# ── Step 2: Build ──────────────────────────────────────────────────────────
echo -e "${BOLD}[2/4] Building PDF...${NC}"
cd "$PROJECT_DIR"
make build > /dev/null 2>&1
echo "  Done."

# ── Step 3: Compress ───────────────────────────────────────────────────────
echo -e "${BOLD}[3/4] Compressing...${NC}"
BEFORE=$(du -h "$PDF" | cut -f1)

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
   -dPDFSETTINGS=/prepress -dNOPAUSE -dBATCH -dQUIET \
   -sOutputFile="${BUILD_DIR}/main-compressed.pdf" \
   "$PDF"

mv "${BUILD_DIR}/main-compressed.pdf" "$PDF"
AFTER=$(du -h "$PDF" | cut -f1)
echo "  ${BEFORE} → ${AFTER}"

# ── Step 4: Copy to output/ ───────────────────────────────────────────────
echo -e "${BOLD}[4/4] Publishing...${NC}"
mkdir -p "$OUTPUT_DIR"
cp "$PDF" "${OUTPUT_DIR}/${FILENAME}"

ln -sf "$FILENAME" "${OUTPUT_DIR}/latest.pdf"

echo ""
echo -e "${GREEN}${BOLD}==== Published: output/${FILENAME}${NC}"
echo -e "${GREEN}       Symlink: output/latest.pdf → ${FILENAME}${NC}"
echo ""
echo "  Date:    ${DATE}"
echo "  Version: v${VERSION}"
echo "  Size:    ${AFTER}"
