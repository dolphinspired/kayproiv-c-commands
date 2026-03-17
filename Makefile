TOOLS := tools

export PATH   := $(CURDIR)/$(TOOLS)/z88dk/bin:$(PATH)
export ZCCCFG := $(CURDIR)/$(TOOLS)/z88dk/lib/config

.PHONY: all setup test clean launch launch-mame

all:
	SRC_DIR=src bash scripts/compile.sh
	bash scripts/make-image.sh

setup:
	bash scripts/setup.sh

test: all
	bash test/run_tests.sh

launch:
	bash scripts/launch-runcpm.sh

launch-mame:
	bash scripts/launch-mame.sh

clean:
	rm -rf build/ bin/
