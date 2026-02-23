#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# check-log.sh — Parse build log and display errors/warnings summary
#
# Usage: ./scripts/check-log.sh
#        make check
# ─────────────────────────────────────────────────────────────────────────────

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${PROJECT_DIR}/build/main.log"

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

if [[ ! -f "$LOG" ]]; then
  echo -e "${RED}Error: build log not found at ${LOG}${NC}"
  echo "Run 'make build' first."
  exit 1
fi

CLEANLOG=$(strings "$LOG")

echo -e "${BOLD}─── Build Log Analysis ───${NC}"
echo ""

ERRORS=0
WARNINGS=0

ERROR_LINES=$(echo "$CLEANLOG" | grep -n "^! " 2>/dev/null || true)
if [[ -n "$ERROR_LINES" ]]; then
  echo -e "${RED}${BOLD}ERRORS:${NC}"
  while IFS= read -r line; do
    echo -e "  ${RED}$line${NC}"
    ERRORS=$((ERRORS + 1))
  done <<< "$ERROR_LINES"
  echo ""
fi

UNDEF_REFS=$(echo "$CLEANLOG" | grep -c "Reference .* undefined" 2>/dev/null || true)
UNDEF_REFS=$((UNDEF_REFS + 0))
if [[ $UNDEF_REFS -gt 0 ]]; then
  echo -e "${YELLOW}${BOLD}UNDEFINED REFERENCES (${UNDEF_REFS}):${NC}"
  echo "$CLEANLOG" | grep "Reference .* undefined" | head -10 | while IFS= read -r line; do
    echo -e "  ${YELLOW}$line${NC}"
  done
  echo ""
  WARNINGS=$((WARNINGS + UNDEF_REFS))
fi

UNDEF_CITES=$(echo "$CLEANLOG" | grep -c "Citation .* undefined" 2>/dev/null || true)
UNDEF_CITES=$((UNDEF_CITES + 0))
if [[ $UNDEF_CITES -gt 0 ]]; then
  echo -e "${YELLOW}${BOLD}UNDEFINED CITATIONS (${UNDEF_CITES}):${NC}"
  echo "$CLEANLOG" | grep "Citation .* undefined" | head -10 | while IFS= read -r line; do
    echo -e "  ${YELLOW}$line${NC}"
  done
  echo ""
  WARNINGS=$((WARNINGS + UNDEF_CITES))
fi

OVERFULL=$(echo "$CLEANLOG" | grep -c "Overfull" 2>/dev/null || true)
OVERFULL=$((OVERFULL + 0))
UNDERFULL=$(echo "$CLEANLOG" | grep -c "Underfull" 2>/dev/null || true)
UNDERFULL=$((UNDERFULL + 0))
if [[ $OVERFULL -gt 0 || $UNDERFULL -gt 0 ]]; then
  echo -e "${YELLOW}Box warnings: ${OVERFULL} overfull, ${UNDERFULL} underfull${NC}"
  echo ""
fi

PKG_WARNS=$(echo "$CLEANLOG" | grep -c "Package .* Warning" 2>/dev/null || true)
PKG_WARNS=$((PKG_WARNS + 0))
if [[ $PKG_WARNS -gt 0 ]]; then
  echo -e "${YELLOW}Package warnings: ${PKG_WARNS}${NC}"
  echo "$CLEANLOG" | grep "Package .* Warning" | sort -u | head -10 | while IFS= read -r line; do
    echo -e "  ${YELLOW}$line${NC}"
  done
  echo ""
fi

echo -e "${BOLD}─── Summary ───${NC}"
if [[ $ERRORS -gt 0 ]]; then
  echo -e "  ${RED}✗ ${ERRORS} error(s) found${NC}"
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo -e "  ${YELLOW}⚠ Build succeeded with ${WARNINGS} warning(s)${NC}"
  exit 0
else
  echo -e "  ${GREEN}✓ Clean build — no errors or warnings${NC}"
  exit 0
fi
