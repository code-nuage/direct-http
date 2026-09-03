build: clean all run

BUILD_PATH = build/
ENTRY_POINT = example/main

clean:
	rm -rf $(BUILD_PATH)

all:
	cyan build --prune
	luarocks make --local

run:
	cd $(BUILD_PATH) && lua $(ENTRY_POINT).lua
