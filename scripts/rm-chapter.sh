#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# rm-chapter.sh — Remove a chapter file and its entry from main.tex
#
# Usage:
#   ./scripts/rm-chapter.sh <number>
#
# Examples:
#   ./scripts/rm-chapter.sh 05
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
MAIN="${SRC_DIR}/main.tex"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <chapter_number>"
  echo "  e.g. $0 05"
  echo ""
  echo "Existing chapters:"
  ls -1 "${SRC_DIR}/chapters/" 2>/dev/null | sed 's/^/  /'
  exit 1
fi

NUM="$1"

shopt -s nullglob
FILES=("${SRC_DIR}"/chapters/ch${NUM}-*.tex)
shopt -u nullglob

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "Error: no chapter file matching ch${NUM}-*.tex found in src/chapters/"
  echo ""
  echo "Existing chapters:"
  ls -1 "${SRC_DIR}/chapters/" 2>/dev/null | sed 's/^/  /'
  exit 1
fi

if [[ ${#FILES[@]} -gt 1 ]]; then
  echo "Error: multiple files match ch${NUM}-*:"
  printf '  %s\n' "${FILES[@]}"
  exit 1
fi

FILEPATH="${FILES[0]}"
FILENAME=$(basename "$FILEPATH")
BASENAME="${FILENAME%.tex}"

echo "Will remove:"
echo "  File:  src/chapters/${FILENAME}"
echo "  Entry: \\input{chapters/${BASENAME}} from src/main.tex"
echo ""
read -rp "Confirm? [y/N] " CONFIRM

if [[ "${CONFIRM,,}" != "y" ]]; then
  echo "Cancelled."
  exit 0
fi

sed -i "/^% Chapter ${NUM}:.*$/d" "$MAIN"
sed -i "/^\\\\input{chapters\/${BASENAME}}$/d" "$MAIN"
sed -i '/^$/N;/^\n$/d' "$MAIN"

rm -f "$FILEPATH"

echo "[DONE] Removed: src/chapters/${FILENAME}"
echo "[DONE] Cleaned: src/main.tex entry removed"
