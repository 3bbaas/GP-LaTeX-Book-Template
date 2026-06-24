<div align="center">
  <img src="docs/banner.png" alt="GP LaTeX Book Template" width="100%" />
</div>

<br/>

A professional **LaTeX book template** for academic and graduation projects — with Docker support, helper scripts, and custom commands.

> **Full book example:** [ANIS Solutions Documentation](https://github.com/ANIS-Solutions/Documentation)

---

## Quick Start

### One-Line Install

```bash
curl -sL https://gist.githubusercontent.com/3bbaas/d65a2f59878a8b3c8774b740d9dcf733/raw/64ac8f74a2a94e0851a5aca636627415af3b6039/gp-latex-template-book.sh | bash -s doc-book
```

Prompts you for your book title, team members, supervisors, logos, etc. — then generates `project.yml` and `metadata.tex` automatically.

### With Docker *(no TeX install needed)*

```bash
make docker         # Build image and run
make docker-shell   # Interactive shell
make docker-watch   # Auto-rebuild on save
```

### Without Docker

**Prerequisites:** `texlive-full`, `latexmk`, `biber`, `python3-pygments`, `make`

```bash
make build   # Compile PDF → build/main.pdf
make watch   # Auto-rebuild on save
make check   # Check build log for errors
make clean   # Remove build artifacts
```

---

## Project Structure

```
src/
├── main.tex            # Master document
├── config.tex          # Packages & settings
├── metadata.tex        # Book metadata (auto-generated)
├── project.yml         # Edit this to set your info
├── glossary.tex        # Abbreviation definitions
├── references.bib      # Bibliography
├── chapters/           # Chapter .tex files
├── frontmatter/        # Title page, abstract, acknowledgments
├── appendices/         # Appendix .tex files
├── styles/             # Layout, colors, commands, minted
├── images/             # Image assets
└── code/               # Code snippet files
```

---

## Helper Commands

```bash
make new-chapter 2         # Scaffold a new chapter
make rm-chapter 2          # Remove a chapter
make new-appendix a        # Add an appendix
make new-abbr jwt JWT "JSON Web Token"   # Add an abbreviation
make wordcount             # Word count report
make compress              # Compress the output PDF
make publish               # Build + compress + version to output/
```

See [USAGE.md](USAGE.md) for full documentation.
