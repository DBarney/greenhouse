LUAJIT_OS=$(shell luajit -e "print(require('ffi').os)")
LUAJIT_ARCH=$(shell luajit -e "print(require('ffi').arch)")
TARGET_DIR=$(LUAJIT_OS)-$(LUAJIT_ARCH)
.PHONY: test greenhouse libs

all: greenhouse

greenhouse: lit
	@./lit make

lit:
	curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh

./test-runner: lit
	@./lit make ./cmd/test_runner/

test: ./test-runner
	mkdir -p ./.test
	@find . -type f -name "*_test.lua" | xargs ./test-runner; \
	rm -rf ./.test

libs:
	gcc -shared -o ./libs/${TARGET_DIR}/libcompare.so ./libs/compare.c
