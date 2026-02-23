#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# new-chapter.sh — Create a new chapter and register it in main.tex
#
# Usage:
#   ./scripts/new-chapter.sh <number> <title>
#
# Examples:
#   ./scripts/new-chapter.sh 04 "System Design"
#   ./scripts/new-chapter.sh 05 "Results and Discussion"
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
MAIN="${SRC_DIR}/main.tex"
MARKER="%% NEW_CHAPTER_HERE %%"

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <chapter_number> <title>"
  echo "  e.g. $0 04 \"System Design\""
  exit 1
fi

NUM="$1"
shift
TITLE="$*"

SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
FILENAME="ch${NUM}-${SLUG}.tex"
FILEPATH="${SRC_DIR}/chapters/${FILENAME}"
LABEL="ch:${SLUG}"

if [[ -f "$FILEPATH" ]]; then
  echo "Error: $FILEPATH already exists!"
  exit 1
fi

cat > "$FILEPATH" << EOF
\\chapter{${TITLE}}
\\label{${LABEL}}

% TODO: Write chapter introduction here.


\\section{Section Title}
\\label{sec:${SLUG}-section1}

% TODO: Write section content here.


\\section{Summary}
\\label{sec:${SLUG}-summary}

% TODO: Summarize the chapter.

EOF

if grep -q "$MARKER" "$MAIN"; then
  ENTRY="% Chapter ${NUM}: ${TITLE}\n\\\\input{chapters/${FILENAME%.tex}}\n"
  sed -i "s|${MARKER}|${ENTRY}\n${MARKER}|" "$MAIN"
  echo "[DONE] Created:    src/chapters/${FILENAME}"
  echo "[DONE] Registered: src/main.tex updated automatically"
else
  echo "[DONE] Created: src/chapters/${FILENAME}"
  echo ""
  echo "[WARN]  Marker '${MARKER}' not found in src/main.tex."
  echo "   Add this line manually (before \\printbibliography):"
  echo "     \\input{chapters/${FILENAME%.tex}}"
fi
