
.PHONY: test greenhouse bed glaze

all: greenhouse bed glaze

greenhouse: lit
	@./lit make

bed: lit

glaze: lit

lit:
	curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh

./test-runner: lit
	@./lit make ./cmd/test_runner/

test: ./test-runner
	@find . -type f -name "*_test.lua" | xargs ./test-runner
