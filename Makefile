BUILD_DIR := build
SRC_DIR   := src
MAIN      := main
LOG       ?= 0

# ─── Argument forwarding ─────────────────────────────────────────────────────
# Usage: make <target> <arg1> <arg2> ...
# Extra words after the target are forwarded to the underlying script.
TARGETS_WITH_ARGS := new-chapter rm-chapter new-appendix new-abbr wordcount codediff

ifneq ($(filter $(TARGETS_WITH_ARGS),$(firstword $(MAKECMDGOALS))),)
  ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ARGS):;@:)
endif

.PHONY: all build clean watch check compress compress-small publish \
        init new-chapter rm-chapter new-appendix new-abbr new-ref wordcount codediff \
        docker docker-build docker-shell docker-watch

# ─── Build ───────────────────────────────────────────────────────────────────

all: init clean build check

build:
	@mkdir -p $(BUILD_DIR)
ifeq ($(LOG),1)
	latexmk -pdf -f -shell-escape -interaction=nonstopmode \
		-output-directory=../$(BUILD_DIR) -cd $(SRC_DIR)/$(MAIN).tex
else
	@latexmk -pdf -f -shell-escape -interaction=nonstopmode \
		-output-directory=../$(BUILD_DIR) -cd $(SRC_DIR)/$(MAIN).tex > /dev/null 2>&1
endif
	@echo ""
	@echo "==== Build complete: $(BUILD_DIR)/$(MAIN).pdf"

watch:
	@mkdir -p $(BUILD_DIR)
	latexmk -pdf -pvc -shell-escape -interaction=nonstopmode \
		-output-directory=../$(BUILD_DIR) -cd $(SRC_DIR)/$(MAIN).tex

clean:
	@rm -rf $(BUILD_DIR)
	@echo "==== Cleaned build directory."

check:
	@./scripts/check-log.sh

compress: ## Optimize PDF size (print quality, 300dpi)
	@if [ ! -f $(BUILD_DIR)/$(MAIN).pdf ]; then echo "Error: run 'make build' first."; exit 1; fi
	@BEFORE=$$(du -h $(BUILD_DIR)/$(MAIN).pdf | cut -f1); \
	gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
		-dPDFSETTINGS=/prepress -dNOPAUSE -dBATCH -dQUIET \
		-sOutputFile=$(BUILD_DIR)/$(MAIN)-compressed.pdf \
		$(BUILD_DIR)/$(MAIN).pdf; \
	AFTER=$$(du -h $(BUILD_DIR)/$(MAIN)-compressed.pdf | cut -f1); \
	mv $(BUILD_DIR)/$(MAIN)-compressed.pdf $(BUILD_DIR)/$(MAIN).pdf; \
	echo "==== Compressed: $$BEFORE → $$AFTER ($(BUILD_DIR)/$(MAIN).pdf)"

compress-small: ## Smaller PDF (screen quality, 150dpi)
	@if [ ! -f $(BUILD_DIR)/$(MAIN).pdf ]; then echo "Error: run 'make build' first."; exit 1; fi
	@BEFORE=$$(du -h $(BUILD_DIR)/$(MAIN).pdf | cut -f1); \
	gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.5 \
		-dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -dQUIET \
		-sOutputFile=$(BUILD_DIR)/$(MAIN)-compressed.pdf \
		$(BUILD_DIR)/$(MAIN).pdf; \
	AFTER=$$(du -h $(BUILD_DIR)/$(MAIN)-compressed.pdf | cut -f1); \
	mv $(BUILD_DIR)/$(MAIN)-compressed.pdf $(BUILD_DIR)/$(MAIN).pdf; \
	echo "==== Compressed: $$BEFORE → $$AFTER ($(BUILD_DIR)/$(MAIN).pdf)"

publish: ## Init + build + compress + versioned copy to output/
	@./scripts/publish.sh

# ─── Scripts ─────────────────────────────────────────────────────────────────

init:
	@./scripts/init.sh

new-chapter:
	@./scripts/new-chapter.sh $(ARGS)

rm-chapter:
	@./scripts/rm-chapter.sh $(ARGS)

new-appendix:
	@./scripts/new-appendix.sh $(ARGS)

new-abbr:
	@./scripts/new-abbr.sh $(ARGS)

new-ref:
	@./scripts/new-ref.sh

wordcount:
	@./scripts/wordcount.sh $(ARGS)

codediff:
	@python3 ./scripts/codediff.py $(ARGS)

# ─── Docker ──────────────────────────────────────────────────────────────────

docker:
	docker compose up --build

docker-build:
	docker compose build

docker-shell:
	docker compose run --rm -it book bash

docker-watch:
	docker compose run --rm book make watch
