# ══════════════════════════════════════════════════════════════════════════════
#  Anis — LaTeX Documentation Build System
# ══════════════════════════════════════════════════════════════════════════════

BUILD_DIR := build
SRC_DIR   := src
MAIN      := main
LOG       ?= 0
QUALITY   ?= prepress   # screen | ebook | printer | prepress

# ─── Paths ───────────────────────────────────────────────────────────────────

PDF       := $(BUILD_DIR)/$(MAIN).pdf
PDF_TMP   := $(BUILD_DIR)/$(MAIN)-compressed.pdf
TEX       := $(SRC_DIR)/$(MAIN).tex

# ─── ANSI colors ─────────────────────────────────────────────────────────────

BOLD  := \033[1m
GREEN := \033[0;32m
CYAN  := \033[0;36m
NC    := \033[0m

# ─── Argument forwarding ─────────────────────────────────────────────────────
# Usage: make <target> [arg1] [arg2] ...
# Extra words after the target are forwarded to the underlying script.

TARGETS_WITH_ARGS := new-chapter rm-chapter new-appendix new-abbr wordcount codediff preview chapter

ifneq ($(filter $(TARGETS_WITH_ARGS),$(firstword $(MAKECMDGOALS))),)
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif

# ─── Phony targets ───────────────────────────────────────────────────────────

.PHONY: all build clean watch check _build-dir_ \
        compress compress-small compress-screen compress-ebook compress-printer compress-prepress \
        publish publish-screen publish-ebook publish-printer publish-prepress publish-raw \
        preview init \
        new-chapter rm-chapter new-appendix new-abbr new-ref \
        wordcount codediff pagecounts chapters chapter \
        docker docker-build docker-shell docker-watch \
        help

.DEFAULT_GOAL := help

# ─── Directory sentinel ───────────────────────────────────────────────────────
# Named _build-dir_ to avoid colliding with the 'build' target.

_build-dir_:
	@mkdir -p $(BUILD_DIR)

# ─── PDF prerequisite guard ───────────────────────────────────────────────────

define require-pdf
	@if [ ! -f $(PDF) ]; then \
		printf "$(BOLD)Error:$(NC) $(PDF) not found — run 'make build' first.\n"; exit 1; \
	fi
endef

# ─── Ghostscript compression macro ───────────────────────────────────────────
# Usage: $(call gs-compress,QUALITY)

define gs-compress
	$(require-pdf)
	@BEFORE=$$(du -h $(PDF) | cut -f1); \
	gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
		-dPDFSETTINGS=/$(1) -dNOPAUSE -dBATCH -dQUIET \
		-sOutputFile=$(PDF_TMP) $(PDF); \
	AFTER=$$(du -h $(PDF_TMP) | cut -f1); \
	mv $(PDF_TMP) $(PDF); \
	printf "$(GREEN)$(BOLD)==== Compressed$(NC) [$(1)]: $$BEFORE → $$AFTER  ($(PDF))\n"
endef

# ══════════════════════════════════════════════════════════════════════════════
#  Core
# ══════════════════════════════════════════════════════════════════════════════

all: init clean build check  ## Full pipeline: init → clean → build → check

build: | _build-dir_  ## Compile LaTeX → PDF
ifeq ($(LOG),1)
	latexmk -pdf -f -shell-escape -interaction=nonstopmode \
		-output-directory=../$(BUILD_DIR) -cd $(TEX)
else
	@latexmk -pdf -f -shell-escape -interaction=nonstopmode \
		-output-directory=../$(BUILD_DIR) -cd $(TEX) > /dev/null 2>&1
endif
	@printf "$(GREEN)$(BOLD)==== Build complete:$(NC) $(PDF)\n"

watch: | _build-dir_  ## Live-recompile on file changes
	latexmk -pdf -pvc -shell-escape -interaction=nonstopmode \
		-output-directory=../$(BUILD_DIR) -cd $(TEX)

clean:  ## Remove build artefacts
	@rm -rf $(BUILD_DIR)
	@printf "$(GREEN)$(BOLD)==== Cleaned$(NC) build directory.\n"

check:  ## Validate LaTeX log for warnings/errors
	@./scripts/check-log.sh

init:  ## Sync metadata from project.yml into LaTeX sources
	@./scripts/init.sh

# ══════════════════════════════════════════════════════════════════════════════
#  Compression
# ══════════════════════════════════════════════════════════════════════════════

compress:          ## Compress PDF — uses QUALITY var (default: prepress). e.g. make compress QUALITY=ebook
	$(call gs-compress,$(QUALITY))

compress-screen:   ## ~72 dpi  · smallest file  · screen only
	$(call gs-compress,screen)

compress-ebook:    ## ~150 dpi · small file     · digital reading
	$(call gs-compress,ebook)

compress-printer:  ## ~300 dpi · moderate size  · general use
	$(call gs-compress,printer)

compress-prepress: ## ~300 dpi · larger file    · print-ready
	$(call gs-compress,prepress)

compress-small: compress-ebook  ## Alias → compress-ebook (backwards compat)

# ══════════════════════════════════════════════════════════════════════════════
#  Publishing
# ══════════════════════════════════════════════════════════════════════════════

publish:           ## Init → build → interactive compress → versioned output/
	@./scripts/publish.sh

publish-screen:    ## Publish with screen quality
	@./scripts/publish.sh --quality screen

publish-ebook:     ## Publish with ebook quality
	@./scripts/publish.sh --quality ebook

publish-printer:   ## Publish with printer quality
	@./scripts/publish.sh --quality printer

publish-prepress:  ## Publish with prepress quality
	@./scripts/publish.sh --quality prepress

publish-raw:       ## Publish without any compression
	@./scripts/publish.sh --no-compress

preview:  ## Build + numbered preview copy to output/ (optional name as arg)
	@./scripts/preview.sh "$(ARGS)"

# ══════════════════════════════════════════════════════════════════════════════
#  Content scaffolding
# ══════════════════════════════════════════════════════════════════════════════

new-chapter:   ## Scaffold a new chapter  (e.g. make new-chapter 3)
	@./scripts/new-chapter.sh $(ARGS)

rm-chapter:    ## Remove a chapter        (e.g. make rm-chapter 3)
	@./scripts/rm-chapter.sh $(ARGS)

new-appendix:  ## Scaffold a new appendix
	@./scripts/new-appendix.sh $(ARGS)

new-abbr:      ## Add an abbreviation entry
	@./scripts/new-abbr.sh $(ARGS)

new-ref:       ## Add a reference entry
	@./scripts/new-ref.sh

# ══════════════════════════════════════════════════════════════════════════════
#  Analysis & stats
# ══════════════════════════════════════════════════════════════════════════════

wordcount:   ## Word count report
	@./scripts/wordcount.sh $(ARGS)

codediff:    ## Diff code listings
	@python3 ./scripts/codediff.py $(ARGS)

pagecounts:  ## Per-chapter page count breakdown
	@./scripts/pagecounts.sh

chapters:    ## Build every chapter as a separate PDF → build/chapters/
	@./scripts/split-chapters.sh

chapter:     ## Build a single chapter PDF  (e.g. make chapter 5)
	@./scripts/split-chapters.sh $(ARGS)

# ══════════════════════════════════════════════════════════════════════════════
#  Docker
# ══════════════════════════════════════════════════════════════════════════════

docker:        ## Build image and start container
	docker compose up --build

docker-build:  ## Build Docker image only
	docker compose build

docker-shell:  ## Open interactive shell in container
	docker compose run --rm -it book bash

docker-watch:  ## Run live-watch inside container
	docker compose run --rm book make watch

# ══════════════════════════════════════════════════════════════════════════════
#  Help
# ══════════════════════════════════════════════════════════════════════════════

help:  ## Show this help
	@printf "\n$(BOLD)  Anis — LaTeX Build System$(NC)\n\n"
	@printf "  $(CYAN)Usage:$(NC)  make <target> [QUALITY=level] [LOG=1] [args...]\n\n"
	@printf "  $(CYAN)Targets:$(NC)\n"
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*##"}; {printf "    $(BOLD)%-22s$(NC) %s\n", $$1, $$2}'
	@printf "\n  $(CYAN)QUALITY levels$(NC) (for compress / make compress QUALITY=…):\n"
	@printf "    %-14s %s\n" "screen"   "~72 dpi  · smallest · screen only"
	@printf "    %-14s %s\n" "ebook"    "~150 dpi · small    · digital reading"
	@printf "    %-14s %s\n" "printer"  "~300 dpi · moderate · general use"
	@printf "    %-14s %s\n" "prepress" "~300 dpi · larger   · print-ready (default)"
	@printf "\n"