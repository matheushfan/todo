#!/usr/bin/env zsh
# Test suite for td-status command (add/rm/ls)
# Covers: LIST-04

source "${0:A:h}/test_helpers.zsh"

TEST_DATA="$(mktemp -d)"
trap "rm -rf '$TEST_DATA'" EXIT INT TERM
export TODOLIST_DATA="$TEST_DATA"

TD_DATA="$TEST_DATA"
TD_ROOT="${0:A:h}/.."
fpath=("$TD_ROOT/lib" "$TD_ROOT/commands" $fpath)
autoload -Uz _td_core && _td_core
autoload -Uz _td_storage && _td_storage

local tasks_file="$TEST_DATA/lists/default/tasks.json"

# ============================================================
# LIST-04: td-status
# ============================================================

printf "\n=== LIST-04: td-status ===\n"

# Test 1: status ls shows default statuses
local ls_out
ls_out=$($TD_BIN status ls 2>&1)
local ls_rc=$?
assert_exit_code "status ls: exits 0" "0" "$ls_rc"
assert_contains "status ls: shows todo" "todo" "$ls_out"
assert_contains "status ls: shows doing" "doing" "$ls_out"
assert_contains "status ls: shows done" "done" "$ls_out"

# Test 2: status (no subcommand) defaults to ls
local ls_default_out
ls_default_out=$($TD_BIN status 2>&1)
local ls_default_rc=$?
assert_exit_code "status (default): exits 0" "0" "$ls_default_rc"
assert_contains "status (default): shows todo" "todo" "$ls_default_out"

# Test 3: status add review exits 0
local add_out
add_out=$($TD_BIN status add review 2>&1)
local add_rc=$?
assert_exit_code "status add review: exits 0" "0" "$add_rc"
assert_contains "status add review: confirmation" "Added status" "$add_out"

# Test 4: status ls now includes review
local ls2_out
ls2_out=$($TD_BIN status ls 2>&1)
assert_contains "status ls: includes review" "review" "$ls2_out"

# Test 5: status add review again fails (duplicate)
local add_dup_out
add_dup_out=$($TD_BIN status add review 2>&1)
local add_dup_rc=$?
assert_exit_code "status add duplicate: returns error" "1" "$add_dup_rc"
assert_contains "status add duplicate: error msg" "already exists" "$add_dup_out"

# Test 6: status add with no args fails
local add_noargs_out
add_noargs_out=$($TD_BIN status add 2>&1)
local add_noargs_rc=$?
assert_exit_code "status add no args: returns error" "1" "$add_noargs_rc"
assert_contains "status add no args: shows usage" "Usage" "$add_noargs_out"

# Test 7: status add with invalid name fails
local add_bad_out
add_bad_out=$($TD_BIN status add "invalid name!" 2>&1)
local add_bad_rc=$?
assert_exit_code "status add invalid name: returns error" "1" "$add_bad_rc"
assert_contains "status add invalid name: error msg" "Invalid status name" "$add_bad_out"

# Test 8: status rm doing exits 0 (no tasks in doing)
local rm_out
rm_out=$($TD_BIN status rm doing 2>&1)
local rm_rc=$?
assert_exit_code "status rm doing: exits 0" "0" "$rm_rc"
assert_contains "status rm doing: confirmation" "Removed status" "$rm_out"

# Test 9: add task, move to review, then try to remove review (has tasks)
local task_out
task_out=$($TD_BIN add "Review test task" 2>&1)
local task_short_id="${task_out##*task }"
task_short_id="${task_short_id:0:4}"

$TD_BIN move "$task_short_id" review 2>/dev/null

local rm_has_tasks_out
rm_has_tasks_out=$($TD_BIN status rm review 2>&1)
local rm_has_tasks_rc=$?
assert_exit_code "status rm with tasks: returns error" "1" "$rm_has_tasks_rc"
assert_contains "status rm with tasks: error msg" "task(s) still using it" "$rm_has_tasks_out"

# Test 10: try to remove all statuses until last one fails
# Currently have: todo, done, review (doing was removed)
$TD_BIN status rm review 2>/dev/null  # will fail (has tasks), so move task first
$TD_BIN move "$task_short_id" todo 2>/dev/null
$TD_BIN status rm review 2>/dev/null  # now should work
$TD_BIN status rm done 2>/dev/null    # remove done (no tasks)

# Now only "todo" remains, try to remove it
local rm_last_out
rm_last_out=$($TD_BIN status rm todo 2>&1)
local rm_last_rc=$?
assert_exit_code "status rm last: returns error" "1" "$rm_last_rc"
assert_contains "status rm last: error msg" "Cannot remove last status" "$rm_last_out"

# Test 11: status rm nonexistent fails
local rm_notfound_out
rm_notfound_out=$($TD_BIN status rm nonexistent 2>&1)
local rm_notfound_rc=$?
assert_exit_code "status rm nonexistent: returns error" "1" "$rm_notfound_rc"
assert_contains "status rm nonexistent: error msg" "not found" "$rm_notfound_out"

# ============================================================
# Summary
# ============================================================

test_summary
