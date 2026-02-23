#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# new-ref.sh — Add a BibTeX reference to references.bib
# Usage: ./scripts/new-ref.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/../src" && pwd)"
BIB="${SRC_DIR}/references.bib"

echo "─── Add New Reference ───"
echo ""
echo "Select type:"
echo "  1) Article (journal paper)"
echo "  2) Book"
echo "  3) InProceedings (conference paper)"
echo "  4) Online (website/URL)"
echo "  5) Manual entry (paste raw BibTeX)"
echo ""
read -rp "Choice [1-5]: " TYPE_CHOICE

case "$TYPE_CHOICE" in
  1)
    read -rp "Citation key (e.g. smith2024): " KEY
    read -rp "Author(s): " AUTHOR
    read -rp "Title: " TITLE
    read -rp "Journal: " JOURNAL
    read -rp "Year: " YEAR
    read -rp "Volume (or Enter to skip): " VOLUME
    read -rp "Pages (e.g. 1--15, or Enter to skip): " PAGES
    {
      echo ""
      echo "@article{${KEY},"
      echo "  author  = {${AUTHOR}},"
      echo "  title   = {${TITLE}},"
      echo "  journal = {${JOURNAL}},"
      echo "  year    = {${YEAR}},"
      [[ -n "$VOLUME" ]] && echo "  volume  = {${VOLUME}},"
      [[ -n "$PAGES" ]]  && echo "  pages   = {${PAGES}},"
      echo "}"
    } >> "$BIB"
    ;;
  2)
    read -rp "Citation key: " KEY
    read -rp "Author(s): " AUTHOR
    read -rp "Title: " TITLE
    read -rp "Publisher: " PUBLISHER
    read -rp "Year: " YEAR
    read -rp "Address (or Enter to skip): " ADDRESS
    {
      echo ""
      echo "@book{${KEY},"
      echo "  author    = {${AUTHOR}},"
      echo "  title     = {${TITLE}},"
      echo "  publisher = {${PUBLISHER}},"
      echo "  year      = {${YEAR}},"
      [[ -n "$ADDRESS" ]] && echo "  address   = {${ADDRESS}},"
      echo "}"
    } >> "$BIB"
    ;;
  3)
    read -rp "Citation key: " KEY
    read -rp "Author(s): " AUTHOR
    read -rp "Title: " TITLE
    read -rp "Conference title: " BOOKTITLE
    read -rp "Year: " YEAR
    read -rp "Pages (or Enter to skip): " PAGES
    {
      echo ""
      echo "@inproceedings{${KEY},"
      echo "  author    = {${AUTHOR}},"
      echo "  title     = {${TITLE}},"
      echo "  booktitle = {${BOOKTITLE}},"
      echo "  year      = {${YEAR}},"
      [[ -n "$PAGES" ]] && echo "  pages     = {${PAGES}},"
      echo "}"
    } >> "$BIB"
    ;;
  4)
    read -rp "Citation key: " KEY
    read -rp "Author/Organization: " AUTHOR
    read -rp "Title: " TITLE
    read -rp "URL: " URL
    read -rp "Year: " YEAR
    read -rp "Access date (e.g. 2026-02-22): " URLDATE
    {
      echo ""
      echo "@online{${KEY},"
      echo "  author  = {${AUTHOR}},"
      echo "  title   = {${TITLE}},"
      echo "  url     = {${URL}},"
      echo "  year    = {${YEAR}},"
      echo "  urldate = {${URLDATE}},"
      echo "}"
    } >> "$BIB"
    ;;
  5)
    echo ""
    echo "Paste your BibTeX entry below (press Ctrl+D when done):"
    { echo ""; cat; } >> "$BIB"
    ;;
  *)
    echo "Invalid choice."
    exit 1
    ;;
esac

echo ""
echo "[DONE] Reference '${KEY:-entry}' added to src/references.bib"
echo "   Use: \\insertref{${KEY:-key}}"
