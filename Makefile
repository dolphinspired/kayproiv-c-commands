TOOLS    := tools
ZCC      := ZCCCFG=$(TOOLS)/z88dk/lib/config $(TOOLS)/z88dk/bin/zcc
RUNCPM   := $(TOOLS)/runcpm/RunCPM
CPMCP    := $(TOOLS)/cpmtools/bin/cpmcp

SRCS     := $(wildcard src/*.c)
TARGETS  := $(patsubst src/%.c,build/%.COM,$(SRCS))

.PHONY: all setup test clean image

setup:
	bash scripts/setup.sh

all: $(TARGETS)

build/%.COM: src/%.c | build
	$(ZCC) +kaypro -create-app -lndos -o $@ $<

build:
	mkdir -p build

test: all
	bash test/run_tests.sh

image: all
	bash scripts/make_image.sh

clean:
	rm -rf build/ disk/
