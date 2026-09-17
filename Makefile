all: clean compile install run

BUILD_PATH = build/
ENTRY_POINT = example/main

clean:
	rm -rf $(BUILD_PATH)

compile:
	cyan build --prune

install:
	luarocks make --local

run:
	cd $(BUILD_PATH) && lua $(ENTRY_POINT).lua
