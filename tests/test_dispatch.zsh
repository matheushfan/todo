#!/usr/bin/env zsh
source "${0:A:h}/test_helpers.zsh"
printf "=== Dispatch Tests ===\n"

# Test 1: Default command (no args) shows board
output=$(TODOLIST_DATA=$(mktemp -d) zsh "$TD_BIN" 2>&1)
assert_contains "no args shows board" "TODO" "$output"

# Test 2: Explicit help command
output=$(zsh "$TD_BIN" help 2>&1)
assert_contains "help command shows usage" "Usage:" "$output"

# Test 3: Version command
# Assert the shape, not the literal version: pinning the number here meant the
# test kept passing against a TD_VERSION that had gone stale two releases back.
output=$(zsh "$TD_BIN" version 2>&1)
assert_eq "version command shows semver" "0" \
  "$([[ "$output" == todo\ v<->.<->.<-> ]]; echo $?)"

# Test 4: Unknown command fails
output=$(zsh "$TD_BIN" nonexistent 2>&1)
ec=$?
assert_contains "unknown cmd shows error" "is not a command" "$output"
assert_exit_code "unknown cmd exits non-zero" "1" "$ec"

# Test 5: Help mentions available commands
output=$(zsh "$TD_BIN" help 2>&1)
assert_contains "help lists help cmd" "help" "$output"
assert_contains "help lists version cmd" "version" "$output"

test_summary
