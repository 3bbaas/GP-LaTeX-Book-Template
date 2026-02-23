#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# new-appendix.sh — Create a new appendix and register it in main.tex
#
# Usage:
#   ./scripts/new-appendix.sh <letter> <title>
#
# Examples:
#   ./scripts/new-appendix.sh b "Survey Results"
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
MAIN="${SRC_DIR}/main.tex"
MARKER="%% NEW_APPENDIX_HERE %%"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <letter> <title>"
  echo "  e.g. $0 b \"Survey Results\""
  exit 1
fi

LETTER="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
shift
TITLE="$*"

FILENAME="appendix-${LETTER}.tex"
FILEPATH="${SRC_DIR}/appendices/${FILENAME}"
LABEL="app:$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')"

if [[ -f "$FILEPATH" ]]; then
  echo "Error: $FILEPATH already exists!"
  exit 1
fi

mkdir -p "${SRC_DIR}/appendices"

cat > "$FILEPATH" << EOF
\\chapter{${TITLE}}
\\label{${LABEL}}

% TODO: Write appendix content here.

EOF

if grep -q "$MARKER" "$MAIN"; then
  ENTRY="  \\\\input{appendices/${FILENAME%.tex}}"
  sed -i "s|${MARKER}|${ENTRY}\n${MARKER}|" "$MAIN"
  echo "[DONE] Created:    src/appendices/${FILENAME}"
  echo "[DONE] Registered: src/main.tex updated automatically"
else
  echo "[DONE] Created: src/appendices/${FILENAME}"
  echo ""
  echo "[WARN]  Marker '${MARKER}' not found in src/main.tex."
  echo "   Add this line manually inside \\begin{appendices}:"
  echo "     \\input{appendices/${FILENAME%.tex}}"
fi
