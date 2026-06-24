#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# publish.sh — Build, compress, and copy versioned PDF to output/
#
# Usage: ./scripts/publish.sh [--quality LEVEL] [--no-compress]
#        make publish
#
# Quality levels:
#   screen   — Lowest quality, smallest file (~72 dpi, max compression)
#   ebook    — Low quality, small file (~150 dpi, good for digital reading)
#   printer  — Good quality, moderate size (~300 dpi, recommended)
#   prepress — High quality, larger file (~300 dpi, print-ready, default)
#   none     — Skip compression entirely
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
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Compression level descriptions ──────────────────────────────────────────
declare -A QUALITY_DESC=(
  [screen]="~72 dpi  · smallest file · screen only"
  [ebook]="~150 dpi · small file    · digital reading"
  [printer]="~300 dpi · moderate size · general use"
  [prepress]="~300 dpi · larger file   · print-ready (default)"
  [none]="no compression  · original size · fastest"
)

declare -A QUALITY_LABEL=(
  [screen]="Screen"
  [ebook]="eBook"
  [printer]="Printer"
  [prepress]="Prepress"
  [none]="None"
)

# ── Parse CLI flags ──────────────────────────────────────────────────────────
QUALITY=""
SKIP_COMPRESS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quality|-q)
      QUALITY="${2:-}"
      shift 2
      ;;
    --no-compress)
      SKIP_COMPRESS=true
      shift
      ;;
    --help|-h)
      echo ""
      echo -e "  ${BOLD}publish.sh${NC} — Build, compress, and publish the PDF"
      echo ""
      echo -e "  ${BOLD}Usage:${NC}"
      echo "    ./scripts/publish.sh [--quality LEVEL] [--no-compress]"
      echo ""
      echo -e "  ${BOLD}Flags:${NC}"
      echo "    --quality, -q LEVEL   Set compression quality directly"
      echo "    --no-compress         Skip compression entirely"
      echo "    --help, -h            Show this help"
      echo ""
      echo -e "  ${BOLD}Quality levels:${NC}"
      for lvl in screen ebook printer prepress none; do
        printf "    %-12s %s\n" "$lvl" "${QUALITY_DESC[$lvl]}"
      done
      echo ""
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown flag: $1${NC}"
      echo "Run with --help for usage."
      exit 1
      ;;
  esac
done

# ── Read metadata from project.yml ──────────────────────────────────────────
yaml_get() {
  grep "^${1}:" "$YML" | head -1 | sed "s/^${1}:[[:space:]]*//" | sed 's/^"//;s/"$//'
}

BOOK_TITLE=$(yaml_get "book_title")
VERSION=$(yaml_get "version")

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

# ── Slugify title ────────────────────────────────────────────────────────────
SLUG=$(echo "$BOOK_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
FILENAME="${SLUG}-v${VERSION}.pdf"
DATE=$(date +%Y-%m-%d)

echo ""
echo -e "${BOLD}─── Publishing ───${NC}"
echo ""
echo -e "  Title:   ${BOOK_TITLE}"
echo -e "  Version: ${VERSION}"
echo -e "  File:    ${FILENAME}"
echo ""

# ── Interactive quality picker (if not passed via flag) ──────────────────────
if [[ "$SKIP_COMPRESS" == false && -z "$QUALITY" ]]; then
  echo -e "${BOLD}[?] Choose compression quality:${NC}"
  echo ""

  LEVELS=(screen ebook printer prepress none)
  DEFAULT_IDX=3  # prepress

  for i in "${!LEVELS[@]}"; do
    lvl="${LEVELS[$i]}"
    label="${QUALITY_LABEL[$lvl]}"
    desc="${QUALITY_DESC[$lvl]}"
    num=$((i + 1))
    if [[ $i -eq $DEFAULT_IDX ]]; then
      echo -e "    ${CYAN}${BOLD}[$num] %-10s${NC}  ${desc}  ${DIM}← default${NC}" | \
        awk -v label="$label" '{gsub(/%-10s/, sprintf("%-10s", label)); print}'
    else
      echo -e "    ${BOLD}[$num] %-10s${NC}  ${desc}" | \
        awk -v label="$label" '{gsub(/%-10s/, sprintf("%-10s", label)); print}'
    fi
  done

  echo ""
  read -r -p "  Enter choice [1-5] (default: 4): " CHOICE
  CHOICE="${CHOICE:-4}"

  if [[ "$CHOICE" =~ ^[1-5]$ ]]; then
    QUALITY="${LEVELS[$((CHOICE - 1))]}"
  else
    echo -e "${RED}  Invalid choice. Using default: prepress${NC}"
    QUALITY="prepress"
  fi

  [[ "$QUALITY" == "none" ]] && SKIP_COMPRESS=true
  echo ""
fi

# Validate --quality flag value if passed via CLI
if [[ -n "$QUALITY" && "$QUALITY" != "none" ]]; then
  if [[ -z "${QUALITY_DESC[$QUALITY]+_}" ]]; then
    echo -e "${RED}Error: unknown quality '${QUALITY}'${NC}"
    echo "Valid values: screen ebook printer prepress none"
    exit 1
  fi
fi

# ── Step 1: Init metadata ────────────────────────────────────────────────────
echo -e "${BOLD}[1/4] Syncing metadata...${NC}"
"${PROJECT_DIR}/scripts/init.sh" > /dev/null 2>&1
echo "  Done."

# ── Step 2: Build ────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/4] Building PDF...${NC}"
cd "$PROJECT_DIR"
make build > /dev/null 2>&1
echo "  Done."

# ── Step 3: Compress ─────────────────────────────────────────────────────────
echo -e "${BOLD}[3/4] Compressing...${NC}"
BEFORE=$(du -h "$PDF" | cut -f1)

if [[ "$SKIP_COMPRESS" == true ]]; then
  echo -e "  ${DIM}Skipped (quality: none)${NC}"
  AFTER="$BEFORE"
else
  echo -e "  Quality: ${CYAN}${BOLD}${QUALITY_LABEL[$QUALITY]}${NC}  ${DIM}(${QUALITY_DESC[$QUALITY]})${NC}"

  gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
     -dPDFSETTINGS=/"${QUALITY}" -dNOPAUSE -dBATCH -dQUIET \
     -sOutputFile="${BUILD_DIR}/main-compressed.pdf" \
     "$PDF"

  mv "${BUILD_DIR}/main-compressed.pdf" "$PDF"
  AFTER=$(du -h "$PDF" | cut -f1)
  echo "  ${BEFORE} → ${AFTER}"
fi

# ── Step 4: Publish ──────────────────────────────────────────────────────────
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
echo "  Quality: ${QUALITY_LABEL[${QUALITY:-none}]}"
echo "  Size:    ${AFTER}"
echo ""
