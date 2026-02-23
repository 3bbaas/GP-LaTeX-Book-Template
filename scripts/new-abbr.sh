#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# new-abbr.sh — Add a new abbreviation to glossary.tex
#
# Usage:
#   ./scripts/new-abbr.sh <key> <SHORT> <Long Form>
#
# Examples:
#   ./scripts/new-abbr.sh dns DNS "Domain Name System"
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
GLOSSARY="${SRC_DIR}/glossary.tex"

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <key> <SHORT> <Long Form>"
  echo "  e.g. $0 dns DNS \"Domain Name System\""
  exit 1
fi

KEY="$1"
SHORT="$2"
shift 2
LONG="$*"

if grep -q "\\\\defabbr{${KEY}}" "$GLOSSARY" 2>/dev/null; then
  echo "Error: abbreviation '${KEY}' already exists in glossary.tex!"
  exit 1
fi

echo "\\defabbr{${KEY}}{${SHORT}}{${LONG}}" >> "$GLOSSARY"

echo "[DONE] Added abbreviation: ${SHORT} = ${LONG}"
echo ""
echo "Use in your .tex files:"
echo "  \\abbr{${KEY}}       → ${SHORT} (with footnote on first use)"
echo "  \\abbrfull{${KEY}}   → ${LONG} (${SHORT})"
echo "  \\abbrshort{${KEY}}  → ${SHORT}"
echo "  \\abbrlong{${KEY}}   → ${LONG}"
