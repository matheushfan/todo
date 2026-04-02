#!/usr/bin/env zsh
# Test helpers -- sourced by test files

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TD_BIN="${0:A:h}/../bin/todo"

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    printf "  PASS: %s\n" "$label"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    printf "  FAIL: %s\n    expected: %s\n    actual:   %s\n" "$label" "$expected" "$actual"
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$haystack" == *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    printf "  PASS: %s\n" "$label"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    printf "  FAIL: %s\n    expected to contain: %s\n    actual: %s\n" "$label" "$needle" "$haystack"
  fi
}

assert_exit_code() {
  local label="$1" expected="$2" actual="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    printf "  PASS: %s\n" "$label"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    printf "  FAIL: %s\n    expected exit code: %s\n    actual exit code:   %s\n" "$label" "$expected" "$actual"
  fi
}

test_summary() {
  printf "\nResults: %d/%d passed" "$TESTS_PASSED" "$TESTS_RUN"
  if (( TESTS_FAILED > 0 )); then
    printf " (%d FAILED)\n" "$TESTS_FAILED"
    return 1
  else
    printf "\n"
    return 0
  fi
}
