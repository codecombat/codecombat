.DEFAULT_GOAL := help

ARGS ?=

.PHONY: help dev dev-ozaria proxy proxy-ozaria build copy-i18n check-i18n generate-rot13 find-coco-ozar-diffs generate-levels svg-to-base64 build-aether

# ——— Help ————————————————————————————————————————————————————————————————————

help: ## Show available script targets
	@echo ""
	@echo "Ad-hoc scripts (run with: make <target> [ARGS=\"...\"])"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ——— Development —————————————————————————————————————————————————————————————

dev: ## Build client with webpack in watch mode (CodeCombat)
	npm run dev

dev-ozaria: ## Build client with webpack in watch mode (Ozaria)
	npm run dev:ozaria

proxy: ## Run local proxy dev server on port 3000 (CodeCombat)
	npm run proxy

proxy-ozaria: ## Run local proxy dev server on port 3001 (Ozaria)
	npm run proxy:ozaria

build: ## Full production build (bower + aether + webpack)
	npm run build

# ——— i18n ————————————————————————————————————————————————————————————————————

copy-i18n: ## Rewrite locale files to match en.js structure, propagate {change} markers
	node scripts/copy-i18n-tags.js $(ARGS)

check-i18n: ## Flag translations suspiciously longer than English originals
	node scripts/check-long-i18n.js $(ARGS)

generate-rot13: ## Generate ROT13 locale for i18n debugging
	node scripts/generateRot13Locale.js $(ARGS)

# ——— Product File Management ————————————————————————————————————————————————

find-coco-ozar-diffs: ## Find and rank .coco./.ozar. file pairs by difference
	node scripts/find-coco-ozar-diffs.mjs $(ARGS)

# ——— Other Tools —————————————————————————————————————————————————————————————

generate-levels: ## Test level generation algorithm (ARGS="--dry --debug")
	node scripts/generateLevels.js $(ARGS)

svg-to-base64: ## Convert SVGs to base64 Sass variables
	bash scripts/convert_svg_to_base64.sh $(ARGS)

build-aether: ## Build Aether code execution engine as separate webpack artifact
	node setup-aether.js $(ARGS)
