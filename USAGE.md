# Template Usage Guide

How to use the custom commands, scripts, and features in this LaTeX template.

---

## Quick Start

```bash
# 1. Edit project metadata
nano src/project.yml

# 2. Generate metadata.tex from project.yml
make init

# 3. Build the PDF
make build
```

---

## Build Commands

```bash
make            # Clean + build
make build      # Compile to build/main.pdf
make watch      # Auto-rebuild on file save
make clean      # Remove build artifacts
```

> **Requires**: `texlive`, `latexmk`, `biber`, and `python3-pygments`.

---

## Docker Build (no local TeX install needed)

### Quick Commands

```bash
make docker         # Build PDF inside container (one-shot)
make docker-build   # Build the Docker image only
make docker-shell   # Open interactive shell inside container
```

### How it works

The project uses **live mounting** — your local directory is mounted directly into the container at `/book`. This means:

- Edit files on your host → changes are **instantly** available in the container
- `build/main.pdf` appears **directly** on your host after building
- No need to rebuild the Docker image after editing `.tex` files

### Step-by-step workflow

```bash
# 1. Build the Docker image (only needed once, or after Dockerfile changes)
make docker-build

# 2. Option A: Build PDF in one shot
make docker

# 2. Option B: Open a shell to build interactively
make docker-shell

# Inside the container shell:
root@container:/book# make build       # compile PDF
root@container:/book# make clean       # clean build artifacts
root@container:/book# make all         # clean + rebuild
root@container:/book# ./scripts/init.sh  # run any script
root@container:/book# exit             # leave container
```

### Using docker compose directly

```bash
# Build image
docker compose build

# Run one-shot build
docker compose up

# Interactive shell
docker compose run --rm book bash

# Run a specific command
docker compose run --rm book make clean
docker compose run --rm book ./scripts/wordcount.sh --tex
```

### Important notes

- The Docker image is **~4 GB** (full TeX Live). First build takes a few minutes to download.
- Rebuild the image (`make docker-build`) only if you change the `Dockerfile`.
- The `build/` output directory is shared — you can open `build/main.pdf` directly on your host.


## Project Structure

| Path                  | Purpose                              |
|-----------------------|--------------------------------------|
| `project.yml`         | Project metadata (YAML) — edit this  |
| `main.tex`            | Master document with marker comments |
| `config.tex`          | Packages & auto-generated metadata   |
| `glossary.tex`        | Abbreviation definitions             |
| `styles/commands.tex` | Custom LaTeX commands                |
| `styles/layout.tex`   | Headers, footers, chapter title style |
| `styles/minted.tex`   | Code highlighting theme & defaults   |
| `chapters/`           | One `.tex` file per chapter          |
| `appendices/`         | One `.tex` file per appendix         |
| `frontmatter/`        | Title page, abstract, acknowledgments |
| `images/`             | Image files (PNG, JPG, PDF)          |
| `code/`               | Source code files for code snippets  |
| `references.bib`      | BibTeX bibliography database         |
| `scripts/`            | Helper shell scripts                 |
| `build/`              | Compiled output (gitignored)         |

---

## Scripts Reference

All scripts are in `scripts/` and are self-contained (no external dependencies).

### `init.sh` — Initialize project from YAML metadata

Reads `project.yml` and generates `metadata.tex`.

```bash
./scripts/init.sh
```

**Workflow:**
1. Edit `project.yml` with your project details
2. Run `./scripts/init.sh`
3. Run `make build`

---

### `new-chapter.sh` — Add a new chapter

Creates the `.tex` file and **auto-inserts** it into `main.tex`.

```bash
./scripts/new-chapter.sh <number> <title>
```

**Examples:**
```bash
./scripts/new-chapter.sh 02 "Background"
./scripts/new-chapter.sh 03 "System Design"
./scripts/new-chapter.sh 04 "Results"
```

**Output:** Creates `chapters/ch02-background.tex` with a pre-filled template and registers it in `main.tex` at the `%% NEW_CHAPTER_HERE %%` marker.

---

### `rm-chapter.sh` — Remove a chapter

Deletes the `.tex` file and removes its entry from `main.tex`.

```bash
./scripts/rm-chapter.sh <number>
```

**Examples:**
```bash
./scripts/rm-chapter.sh 03   # removes ch03-*.tex + its main.tex entry
```

Run without arguments to see existing chapters. Asks for confirmation before deleting.

---

### `new-appendix.sh` — Add a new appendix

Creates the `.tex` file and **auto-inserts** it into `main.tex`.

```bash
./scripts/new-appendix.sh <letter> <title>
```

**Examples:**
```bash
./scripts/new-appendix.sh a "Survey Results"
./scripts/new-appendix.sh b "API Endpoints"
```

---

### `new-abbr.sh` — Add an abbreviation

Adds a new abbreviation definition to `glossary.tex`.

```bash
./scripts/new-abbr.sh <key> <SHORT> <long form>
```

**Examples:**
```bash
./scripts/new-abbr.sh dns DNS "Domain Name System"
./scripts/new-abbr.sh mvc MVC "Model-View-Controller"
./scripts/new-abbr.sh jwt JWT "JSON Web Token"
```

---

### `new-ref.sh` — Add a bibliography reference

Interactive script that guides you through adding a BibTeX entry.

```bash
./scripts/new-ref.sh
```

Supports: Article, Book, Conference Paper, Online/URL, or raw BibTeX paste.

---

### `wordcount.sh` — Count words

```bash
./scripts/wordcount.sh         # Word count from compiled PDF
./scripts/wordcount.sh --tex   # Word count from .tex source files
```

---

## Custom LaTeX Commands

### Insert an Image

```latex
\insertimage{filename.png}{Caption text}{fig:label}{0.8\textwidth}

See Figure~\ref{fig:label} for details.
```

### Insert Two Images Side by Side

```latex
\inserttwoimages
  {file1.png}{Caption A}{fig:a}
  {file2.png}{Caption B}{fig:b}
  {Overall caption}{fig:both}
```

### Insert a Table

```latex
\inserttable{Caption}{tab:label}{lcc}{
  \toprule
  \textbf{Col 1} & \textbf{Col 2} & \textbf{Col 3} \\
  \midrule
  Data 1 & Data 2 & Data 3 \\
  \bottomrule
}
```

### Insert Code from a File

```latex
\insertcode{code/sample.py}{python}{Caption}{lst:label}
```

### Insert Specific Lines from a File

```latex
\insertcodelines{code/sample.py}{python}{5}{15}{Caption}{lst:label}
```

### Insert a Citation

```latex
\insertref{knuth1984}
```

### Callout Boxes

```latex
\note{This is an informational note.}
\warningbox{This is a warning — be careful!}
\tipbox{This is a helpful tip.}
```

---

## Abbreviations

Define abbreviations in `glossary.tex` (or via `./scripts/new-abbr.sh`):

```latex
\defabbr{api}{API}{Application Programming Interface}
```

Use in your text:

| Command           | Output                                          |
|-------------------|-------------------------------------------------|
| `\abbr{api}`      | First use: **API** + footnote. Later: **API**   |
| `\abbrfull{api}`  | Application Programming Interface (API)         |
| `\abbrshort{api}` | API                                             |
| `\abbrlong{api}`  | Application Programming Interface               |

---

## Controlling Paragraph Indentation

Every paragraph has a 0.5 cm indent (including first paragraphs after headings).

**To skip indentation** on a specific paragraph, place `\noindent` on **the same line** as the text:

```latex
\noindent The following list summarizes the key findings:

\begin{enumerate}
  \item First item
  \item Second item
\end{enumerate}
```

> **Important:** `\noindent` must be on the **same line** as the paragraph text. If separated by a blank line, it applies to an empty paragraph instead.

---

## Page Numbering

| Section       | Style                |
|---------------|----------------------|
| Front matter  | Roman (i, ii, iii …) |
| Main chapters | Arabic (1, 2, 3 …)  |
| Appendices    | A.1, A.2, B.1 …     |

This is handled automatically in `main.tex`.

---

## Marker Comments in `main.tex`

Scripts use these markers to auto-insert content:

| Marker                    | Used by                |
|---------------------------|------------------------|
| `%% NEW_CHAPTER_HERE %%`  | `new-chapter.sh`       |
| `%% NEW_APPENDIX_HERE %%` | `new-appendix.sh`      |

**Do not remove these markers** — they are how scripts know where to insert new entries.
