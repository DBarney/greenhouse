
.PHONY: test

./test-runner:
	@lit make ./cmd/test_runner/

test: ./test-runner
	@find . -type f -name "*_test.lua" | xargs ./test-runner
