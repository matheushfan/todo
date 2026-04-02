#!/usr/bin/env zsh
# Test suite for td-tag command and td-add -t flag
# Covers: TAG-01

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
# TAG-01: td-tag add/rm
# ============================================================

printf "\n=== TAG-01: td-tag ===\n"

# Create a task for tag tests
local add_out
add_out=$($TD_BIN add "Tag test task" 2>&1)
local short_id="${add_out##*task }"
short_id="${short_id:0:4}"

# Test 1: tag add exits 0
local tag_add_out
tag_add_out=$($TD_BIN tag add "$short_id" urgent 2>&1)
local tag_add_rc=$?
assert_exit_code "tag add: exits 0" "0" "$tag_add_rc"
assert_contains "tag add: confirmation" "Tagged" "$tag_add_out"

# Test 2: verify tag in JSON
local stored
stored=$(cat "$tasks_file" 2>/dev/null)
assert_contains "tag add: urgent in JSON" '"urgent"' "$stored"

# Test 3: tag add same tag again (idempotent, no duplicate)
local tag_dup_out
tag_dup_out=$($TD_BIN tag add "$short_id" urgent 2>&1)
local tag_dup_rc=$?
assert_exit_code "tag add duplicate: exits 0" "0" "$tag_dup_rc"

# Test 4: verify only one urgent in tags
local tag_count
tag_count=$(TASK_PREFIX="${short_id:u}" JSON_DATA="$(cat "$tasks_file")" osascript -l JavaScript -e '
  function run() {
    var env = $.NSProcessInfo.processInfo.environment;
    var data = JSON.parse(env.objectForKey("JSON_DATA").js);
    var prefix = env.objectForKey("TASK_PREFIX").js;
    var task = data.tasks.filter(function(t) { return t.id.toUpperCase().indexOf(prefix) === 0; })[0];
    return "" + task.tags.filter(function(t) { return t === "urgent"; }).length;
  }
' 2>/dev/null)
assert_eq "tag add duplicate: only one urgent" "1" "$tag_count"

# Test 5: tag rm exits 0
local tag_rm_out
tag_rm_out=$($TD_BIN tag rm "$short_id" urgent 2>&1)
local tag_rm_rc=$?
assert_exit_code "tag rm: exits 0" "0" "$tag_rm_rc"
assert_contains "tag rm: confirmation" "Removed tag" "$tag_rm_out"

# Test 6: verify tags empty after removal
local tags_after
tags_after=$(TASK_PREFIX="${short_id:u}" JSON_DATA="$(cat "$tasks_file")" osascript -l JavaScript -e '
  function run() {
    var env = $.NSProcessInfo.processInfo.environment;
    var data = JSON.parse(env.objectForKey("JSON_DATA").js);
    var prefix = env.objectForKey("TASK_PREFIX").js;
    var task = data.tasks.filter(function(t) { return t.id.toUpperCase().indexOf(prefix) === 0; })[0];
    return "" + task.tags.length;
  }
' 2>/dev/null)
assert_eq "tag rm: tags empty after removal" "0" "$tags_after"

# Test 7: tag add with no args fails
local tag_noargs_out
tag_noargs_out=$($TD_BIN tag add 2>&1)
local tag_noargs_rc=$?
assert_exit_code "tag add no args: returns error" "1" "$tag_noargs_rc"
assert_contains "tag add no args: shows usage" "Usage" "$tag_noargs_out"

# Test 8: tag add with invalid tag name fails
local tag_bad_out
tag_bad_out=$($TD_BIN tag add "$short_id" "bad name!" 2>&1)
local tag_bad_rc=$?
assert_exit_code "tag add invalid name: returns error" "1" "$tag_bad_rc"
assert_contains "tag add invalid name: error msg" "Invalid tag" "$tag_bad_out"

# ============================================================
# TAG-01: td-add -t flag
# ============================================================

printf "\n=== TAG-01: td-add -t ===\n"

# Test 9: add with -t creates task with tags
local tagged_add_out
tagged_add_out=$($TD_BIN add -t work -t urgent "Tagged task" 2>&1)
local tagged_add_rc=$?
assert_exit_code "add -t: exits 0" "0" "$tagged_add_rc"
assert_contains "add -t: confirmation" "Created task" "$tagged_add_out"

# Test 10: verify both tags in JSON
local tagged_stored
tagged_stored=$(cat "$tasks_file" 2>/dev/null)
assert_contains "add -t: work tag in JSON" '"work"' "$tagged_stored"
assert_contains "add -t: urgent tag in JSON" '"urgent"' "$tagged_stored"

# Test 11: verify the new task has exactly both tags
local tagged_short_id="${tagged_add_out##*task }"
tagged_short_id="${tagged_short_id:0:4}"
local tagged_tags
tagged_tags=$(TASK_PREFIX="${tagged_short_id:u}" JSON_DATA="$(cat "$tasks_file")" osascript -l JavaScript -e '
  function run() {
    var env = $.NSProcessInfo.processInfo.environment;
    var data = JSON.parse(env.objectForKey("JSON_DATA").js);
    var prefix = env.objectForKey("TASK_PREFIX").js;
    var task = data.tasks.filter(function(t) { return t.id.toUpperCase().indexOf(prefix) === 0; })[0];
    return JSON.stringify(task.tags);
  }
' 2>/dev/null)
assert_contains "add -t: has work tag" "work" "$tagged_tags"
assert_contains "add -t: has urgent tag" "urgent" "$tagged_tags"

# Test 12: add with invalid tag via -t fails
local bad_tag_out
bad_tag_out=$($TD_BIN add -t "bad!" "Bad tag task" 2>&1)
local bad_tag_rc=$?
assert_exit_code "add -t invalid: returns error" "1" "$bad_tag_rc"
assert_contains "add -t invalid: error msg" "Invalid tag" "$bad_tag_out"

# ============================================================
# Summary
# ============================================================

test_summary
