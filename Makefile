VERSION := $(shell grep '^version' drago.toml | sed 's/.*"\(.*\)"/\1/')
OUT     := drago.bin

.PHONY: build sync-version

build: sync-version
	PATH="$$HOME/bin_wrap:$$PATH" thagc build src/main.tg -o $(OUT)

sync-version:
	@echo "  version: $(VERSION)"
	@sed -i 's|return str\.concat("", "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*")|return str.concat("", "$(VERSION)")|' src/main.tg
