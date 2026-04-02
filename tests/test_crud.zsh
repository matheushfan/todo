#!/usr/bin/env zsh
# Test suite for CRUD commands (td-add, td-ls)
# Covers: TASK-01 (add), TASK-04 (ls), _td_resolve_task_id

source "${0:A:h}/test_helpers.zsh"

# Isolated test data dir
TEST_DATA="$(mktemp -d)"
trap "rm -rf '$TEST_DATA'" EXIT INT TERM
export TODOLIST_DATA="$TEST_DATA"

# Load modules for direct function tests
TD_DATA="$TEST_DATA"
TD_ROOT="${0:A:h}/.."
fpath=("$TD_ROOT/lib" "$TD_ROOT/commands" $fpath)
autoload -Uz _td_core && _td_core
autoload -Uz _td_storage && _td_storage

# ============================================================
# TASK-01: td-add
# ============================================================

printf "\n=== TASK-01: td-add ===\n"

# Test 1: add creates task with title
local add_out
add_out=$($TD_BIN add Buy milk 2>&1)
local add_rc=$?
assert_exit_code "add: creates task (exit 0)" "0" "$add_rc"
assert_contains "add: prints confirmation" "Created task" "$add_out"

# Test 2: add returns short ID in output (8 hex-like chars)
local short_id
short_id=$(printf '%s' "$add_out" | grep -oE '[A-F0-9]{8}')
assert_contains "add: returns short ID" "$short_id" "$add_out"

# Test 3: add with no args returns error
local add_noargs
add_noargs=$($TD_BIN add 2>&1)
local add_noargs_rc=$?
assert_exit_code "add: no args returns error" "1" "$add_noargs_rc"
assert_contains "add: no args shows usage" "Usage" "$add_noargs"

# Test 4: task appears in storage
local tasks_file="$TEST_DATA/lists/default/tasks.json"
local stored
stored=$(cat "$tasks_file" 2>/dev/null)
assert_contains "add: task in storage" "Buy milk" "$stored"

# Test 5: special characters in title
local add_special_out
add_special_out=$($TD_BIN add "Fix bug #42 & deploy" 2>&1)
local add_special_rc=$?
assert_exit_code "add: special chars (exit 0)" "0" "$add_special_rc"

# ============================================================
# _td_resolve_task_id tests
# ============================================================

printf "\n=== _td_resolve_task_id ===\n"

# Get a known task ID from storage
_td_storage_init
local resolve_file
resolve_file="$(_td_storage_list_path)"
local full_id
full_id=$(_td_storage_add_task "$resolve_file" "resolve test task") || true

# Test 10: valid prefix resolves
local prefix="${full_id:0:4}"
local resolved
resolved=$(_td_resolve_task_id "$resolve_file" "$prefix" 2>/dev/null)
local resolve_rc=$?
assert_exit_code "resolve: valid prefix (exit 0)" "0" "$resolve_rc"
assert_eq "resolve: returns full ID" "$full_id" "$resolved"

# Test 11: invalid prefix returns error
_td_resolve_task_id "$resolve_file" "ZZZZZZ" 2>/dev/null
local bad_rc=$?
assert_exit_code "resolve: invalid prefix (exit 1)" "1" "$bad_rc"

# ============================================================
# TASK-04: td-ls
# ============================================================

printf "\n=== TASK-04: td-ls ===\n"

# Test 6: empty list shows friendly message (use fresh temp dir)
local fresh_data="$(mktemp -d)"
local ls_empty_out
ls_empty_out=$(TODOLIST_DATA="$fresh_data" $TD_BIN ls 2>&1)
assert_contains "ls: empty shows friendly message" "No tasks yet" "$ls_empty_out"
rm -rf "$fresh_data"

# Test 7: shows task after add
local ls_out
ls_out=$($TD_BIN ls 2>&1)
assert_contains "ls: shows task title" "Buy milk" "$ls_out"

# Test 8: shows header with ID column
assert_contains "ls: header has ID" "ID" "$ls_out"

# Test 9: shows multiple tasks
$TD_BIN add "Second task" >/dev/null 2>&1
local ls_multi
ls_multi=$($TD_BIN ls 2>&1)
assert_contains "ls: shows first task" "Buy milk" "$ls_multi"
assert_contains "ls: shows second task" "Second task" "$ls_multi"

# ============================================================
# TASK-02: td-edit
# ============================================================

printf "\n=== TASK-02: td-edit ===\n"

# Test: edit changes task title
local edit_add_out
edit_add_out=$($TD_BIN add "Original title" 2>&1)
local edit_short_id="${edit_add_out##*task }"
edit_short_id="${edit_short_id:0:4}"
local edit_out
edit_out=$($TD_BIN edit "$edit_short_id" New title 2>&1)
local edit_rc=$?
assert_exit_code "edit: changes task title (exit 0)" "0" "$edit_rc"
local edit_ls_out
edit_ls_out=$($TD_BIN ls 2>&1)
assert_contains "edit: new title appears in ls" "New title" "$edit_ls_out"

# Test: edit no args returns error
local edit_noargs_out
edit_noargs_out=$($TD_BIN edit 2>&1)
local edit_noargs_rc=$?
assert_exit_code "edit: no args returns error" "1" "$edit_noargs_rc"

# Test: edit no new title returns error
local edit_notitle_add
edit_notitle_add=$($TD_BIN add "No title edit" 2>&1)
local edit_notitle_id="${edit_notitle_add##*task }"
edit_notitle_id="${edit_notitle_id:0:4}"
local edit_notitle_out
edit_notitle_out=$($TD_BIN edit "$edit_notitle_id" 2>&1)
local edit_notitle_rc=$?
assert_exit_code "edit: no new title returns error" "1" "$edit_notitle_rc"

# Test: edit invalid ID returns error
local edit_bad_out
edit_bad_out=$($TD_BIN edit ZZZZZZ "text" 2>&1)
local edit_bad_rc=$?
assert_exit_code "edit: invalid ID returns error" "1" "$edit_bad_rc"
assert_contains "edit: invalid ID shows not found" "No task matching" "$edit_bad_out"

# ============================================================
# TASK-03: td-rm
# ============================================================

printf "\n=== TASK-03: td-rm ===\n"

# Test: rm removes task
local rm_add_out
rm_add_out=$($TD_BIN add "Delete me" 2>&1)
local rm_short_id="${rm_add_out##*task }"
rm_short_id="${rm_short_id:0:4}"
local rm_out
rm_out=$($TD_BIN rm "$rm_short_id" 2>&1)
local rm_rc=$?
assert_exit_code "rm: removes task (exit 0)" "0" "$rm_rc"
local rm_ls_out
rm_ls_out=$($TD_BIN ls 2>&1)
if [[ "$rm_ls_out" != *"Delete me"* ]]; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  printf "  PASS: rm: task no longer in ls\n"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf "  FAIL: rm: task still in ls\n    actual: %s\n" "$rm_ls_out"
fi

# Test: rm no args returns error
local rm_noargs_out
rm_noargs_out=$($TD_BIN rm 2>&1)
local rm_noargs_rc=$?
assert_exit_code "rm: no args returns error" "1" "$rm_noargs_rc"

# Test: rm invalid ID returns error
local rm_bad_out
rm_bad_out=$($TD_BIN rm ZZZZZZ 2>&1)
local rm_bad_rc=$?
assert_exit_code "rm: invalid ID returns error" "1" "$rm_bad_rc"

# ============================================================
# Summary
# ============================================================

test_summary
