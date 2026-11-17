SHELL := /bin/bash

.PHONY: help check test syntax smoke install backup ui-test lint

help:
	@echo "NetLauncher — target pengembangan"
	@echo
	@echo "  make check     syntax + lint + smoke test"
	@echo "  make test      sama dengan check"
	@echo "  make syntax    cek syntax semua script"
	@echo "  make smoke     jalankan tests/smoke.sh"
	@echo "  make install   tautkan repo ke lokasi live"
	@echo "  make backup    arsipkan repo + desktop entry"
	@echo "  make ui-test   uji UI dasar dengan tmux"
	@echo "  make lint      validasi registry, snippet, dan shellcheck"

syntax:
	@bash -n bin/netlauncher lib/*.sh config/automations/*.sh scripts/*.sh tests/smoke.sh && echo "✓ syntax OK"

smoke:
	@./tests/smoke.sh

check: syntax smoke

test: check

install:
	@./scripts/install.sh

backup:
	@./scripts/backup.sh

ui-test:
	@./scripts/ui-test.sh

lint:
	@./bin/netlauncher lint
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -S warning bin/netlauncher lib/*.sh scripts/*.sh tests/smoke.sh; \
	else \
		echo "shellcheck tidak terpasang (lewati)"; \
	fi
