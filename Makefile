.PHONY: help

help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F '##' '{printf "%-15s %s\n", $$1, $$2}'

update-index: ## Update the file index
	./indexer.sh