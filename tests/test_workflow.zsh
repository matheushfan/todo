#!/usr/bin/env zsh
# Test suite for workflow commands (td-done, td-move, td-priority, td-add -p)
# Covers: TASK-05, TASK-06, PRIO-01

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
# TASK-05: td-done
# ============================================================

printf "\n=== TASK-05: td-done ===\n"

# Test 1: done marks task as completed
local add_out
add_out=$($TD_BIN add "Done test task" 2>&1)
local short_id="${add_out##*task }"
short_id="${short_id:0:4}"

local done_out
done_out=$($TD_BIN done "$short_id" 2>&1)
local done_rc=$?
assert_exit_code "done: marks task completed (exit 0)" "0" "$done_rc"
assert_contains "done: prints confirmation" "Completed task" "$done_out"

# Test 2: task status is "done" in storage
local stored
stored=$(cat "$tasks_file" 2>/dev/null)
assert_contains "done: status is done in JSON" '"status": "done"' "$stored"

# Test 3: done with no args returns error
local done_noargs
done_noargs=$($TD_BIN done 2>&1)
local done_noargs_rc=$?
assert_exit_code "done: no args returns error" "1" "$done_noargs_rc"
assert_contains "done: no args shows usage" "Usage" "$done_noargs"

# Test 4: done with invalid ID returns error
local done_bad
done_bad=$($TD_BIN done ZZZZZZ 2>&1)
local done_bad_rc=$?
assert_exit_code "done: invalid ID returns error" "1" "$done_bad_rc"

# ============================================================
# TASK-06: td-move
# ============================================================

printf "\n=== TASK-06: td-move ===\n"

# Test 5: move changes status to "doing"
local move_add_out
move_add_out=$($TD_BIN add "Move test task" 2>&1)
local move_short_id="${move_add_out##*task }"
move_short_id="${move_short_id:0:4}"

local move_out
move_out=$($TD_BIN move "$move_short_id" doing 2>&1)
local move_rc=$?
assert_exit_code "move: changes status (exit 0)" "0" "$move_rc"
assert_contains "move: prints confirmation" "Moved task" "$move_out"

# Test 6: verify status changed in JSON
local move_stored
move_stored=$(cat "$tasks_file" 2>/dev/null)
assert_contains "move: status is doing in JSON" '"status": "doing"' "$move_stored"

# Test 7: move with invalid status returns error
local move_invalid_out
move_invalid_out=$($TD_BIN move "$move_short_id" invalid_xyz 2>&1)
local move_invalid_rc=$?
assert_exit_code "move: invalid status returns error" "1" "$move_invalid_rc"
assert_contains "move: invalid status shows error" "Invalid status" "$move_invalid_out"

# Test 8: move with no args returns error
local move_noargs
move_noargs=$($TD_BIN move 2>&1)
local move_noargs_rc=$?
assert_exit_code "move: no args returns error" "1" "$move_noargs_rc"
assert_contains "move: no args shows usage" "Usage" "$move_noargs"

# ============================================================
# PRIO-01: td-add -p and td-priority
# ============================================================

printf "\n=== PRIO-01: td-add -p and td-priority ===\n"

# Test 9: add with -p high creates task with high priority
local prio_add_out
prio_add_out=$($TD_BIN add -p high "High priority task" 2>&1)
local prio_add_rc=$?
assert_exit_code "add -p high: creates task (exit 0)" "0" "$prio_add_rc"

# Test 10: verify high priority in JSON
local prio_stored
prio_stored=$(cat "$tasks_file" 2>/dev/null)
assert_contains "add -p high: priority is high in JSON" '"priority": "high"' "$prio_stored"

# Test 11: add without -p defaults to medium priority
local default_add_out
default_add_out=$($TD_BIN add "Default priority task" 2>&1)
local default_add_rc=$?
assert_exit_code "add: default priority (exit 0)" "0" "$default_add_rc"

local default_stored
default_stored=$(cat "$tasks_file" 2>/dev/null)
assert_contains "add: default priority is medium in JSON" '"priority": "medium"' "$default_stored"

# Test 12: add with invalid priority returns error
local bad_prio_out
bad_prio_out=$($TD_BIN add -p invalid "Bad priority" 2>&1)
local bad_prio_rc=$?
assert_exit_code "add -p invalid: returns error" "1" "$bad_prio_rc"
assert_contains "add -p invalid: shows error" "Invalid priority" "$bad_prio_out"

# Test 13: priority command changes priority
local prio_change_add
prio_change_add=$($TD_BIN add "Priority change test" 2>&1)
local prio_change_id="${prio_change_add##*task }"
prio_change_id="${prio_change_id:0:4}"

local prio_change_out
prio_change_out=$($TD_BIN priority "$prio_change_id" low 2>&1)
local prio_change_rc=$?
assert_exit_code "priority: changes priority (exit 0)" "0" "$prio_change_rc"
assert_contains "priority: prints confirmation" "Set priority" "$prio_change_out"

# Test 14: verify priority changed to low in JSON
local prio_change_stored
prio_change_stored=$(cat "$tasks_file" 2>/dev/null)
assert_contains "priority: value is low in JSON" '"priority": "low"' "$prio_change_stored"

# Test 15: priority with invalid value returns error
local prio_invalid_out
prio_invalid_out=$($TD_BIN priority "$prio_change_id" invalid 2>&1)
local prio_invalid_rc=$?
assert_exit_code "priority: invalid value returns error" "1" "$prio_invalid_rc"
assert_contains "priority: invalid value shows error" "Invalid priority" "$prio_invalid_out"

# Test 16: priority with no args returns error
local prio_noargs
prio_noargs=$($TD_BIN priority 2>&1)
local prio_noargs_rc=$?
assert_exit_code "priority: no args returns error" "1" "$prio_noargs_rc"
assert_contains "priority: no args shows usage" "Usage" "$prio_noargs"

# ============================================================
# Summary
# ============================================================

test_summary
