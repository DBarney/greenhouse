LUAJIT_OS=$(shell ./luajit -e "print(require('ffi').os)")
LUAJIT_ARCH=$(shell ./luajit -e "print(require('ffi').arch)")
TARGET_DIR=$(LUAJIT_OS)-$(LUAJIT_ARCH)
LMDB_DIR=$(LUAJIT_OS)_$(LUAJIT_ARCH)
.PHONY: test greenhouse libs

all: greenhouse

greenhouse: lit libs
	@./lit make

lit:
	curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh

test: greenhouse
	mkdir -p ./.test
	rm -rf ./.test/*
	@find . -type f -name "*_test.lua" | xargs ./greenhouse test

libs: ./deps/lmmdb/${LMDB_DIR}/liblmdb.so ./libs/${TARGET_DIR}/libcompare.so



./libs/${TARGET_DIR}/libcompare.so: ./libs/${TARGET_DIR}
	gcc -shared -o ./libs/${TARGET_DIR}/libcompare.so ./libs/compare.c

./libs/${TARGET_DIR}:
	mkdir -p ./libs/${TARGET_DIR}

./deps/lmmdb/${LMDB_DIR}/liblmdb.so: ./lmdb/libraries/liblmdb/liblmdb.so ./deps/lmmdb/${LMDB_DIR}
	mv ./lmdb/libraries/liblmdb/liblmdb.so ./deps/lmmdb/${LMDB_DIR}/liblmdb.so

./deps/lmmdb/${LMDB_DIR}:
	mkdir -p ./deps/lmmdb/${LMDB_DIR}

./lmdb/libraries/liblmdb/liblmdb.so: lmdb
	make -C lmdb/libraries/liblmdb/

lmdb:
	git clone https://github.com/LMDB/lmdb
