# LaTeX Book Template

A professional LaTeX book template with Docker support, helper scripts, and custom commands.

## One-Line Install

Set up a new project with interactive metadata prompts:

```bash
curl -sL <gist-raw-url>/install.sh | bash
```

Or run locally after cloning:

```bash
bash scripts/install.sh
```

The script will prompt you for your book title, team members, supervisors, logos, and more — then generate `project.yml` and `metadata.tex` automatically.

## Quick Start

### With Docker (recommended — no TeX install needed)

```bash
# Single command: build the PDF
docker build -t book . && docker run --rm -v "$(pwd):/book" book

# Auto-rebuild on file save (watch mode)
docker build -t book . && docker run --rm -v "$(pwd):/book" book make watch

# Or use docker compose
make docker
```

The compiled PDF will be at `build/main.pdf`.

### Without Docker

**Prerequisites:** `texlive-full`, `latexmk`, `biber`, `python3-pygments`, `make`

```bash
make build      # Compile PDF
make watch      # Auto-rebuild on save
make clean      # Clean build artifacts
make check      # Check build log for errors
```

## Docker Commands

```bash
# One-shot build
make docker

# Interactive shell inside container
make docker-shell

# Watch mode (auto-rebuild on save)
make docker-watch
```

Since the project is **live-mounted**, edits on your host are instantly available in the container and `build/main.pdf` appears directly on your host.

## Project Structure

```
├── src/                    # LaTeX source files
│   ├── main.tex            # Master document
│   ├── config.tex          # Packages & metadata
│   ├── project.yml         # Project metadata (YAML)
│   ├── glossary.tex        # Abbreviation definitions
│   ├── references.bib      # Bibliography
│   ├── chapters/           # Chapter .tex files
│   ├── appendices/         # Appendix .tex files
│   ├── frontmatter/        # Title page, abstract, acknowledgments
│   ├── styles/             # Layout, commands, minted config
│   ├── images/             # Image assets
│   └── code/               # Code snippet files
├── example/                # Example content (full project reference)
├── docs/                   # Documentation website
├── build/                  # Compiled output (gitignored)
├── scripts/                # Helper shell scripts
├── Dockerfile
├── docker-compose.yml
├── Makefile
└── USAGE.md                # Full template usage guide
```

## Helper Commands

All scripts can be run via `make` with arguments:

```bash
make new-chapter 02 "Background"               # Add a new chapter
make rm-chapter 02                              # Remove a chapter
make new-appendix a "Survey Data"               # Add an appendix
make new-abbr jwt JWT "JSON Web Token"          # Add an abbreviation
make new-ref                                    # Add a bibliography reference (interactive)
make wordcount                                  # Count words in PDF
make wordcount --tex                            # Count words in .tex sources
make codediff file_a file_b -o out.diff         # Generate a code diff
make check                                      # Check build log for errors
```

See [USAGE.md](USAGE.md) for full documentation.

