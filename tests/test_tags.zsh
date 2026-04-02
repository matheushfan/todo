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
# TAG-02: Filtering
# ============================================================

printf "\n=== TAG-02: Filtering ===\n"

# Clean slate: remove all tasks, add 3 with different status/priority/tags
# We need to work with a fresh list to get predictable results
local filter_data='{"name":"default","statuses":["todo","doing","done"],"tasks":[]}'
printf '%s\n' "$filter_data" > "$tasks_file"

# Create 3 tasks: todo/alta+work, doing/media+personal, done/baixa
local f_out1 f_out2 f_out3
f_out1=$($TD_BIN add -p alta -t work "Filter task one" 2>&1)
local f_id1="${f_out1##*task }"
f_id1="${f_id1:0:8}"

# Move second task to doing
f_out2=$($TD_BIN add -p media -t personal "Filter task two" 2>&1)
local f_id2="${f_out2##*task }"
f_id2="${f_id2:0:4}"
$TD_BIN move "$f_id2" doing >/dev/null 2>&1

# Move third task to done
f_out3=$($TD_BIN add -p baixa "Filter task three" 2>&1)
local f_id3="${f_out3##*task }"
f_id3="${f_id3:0:4}"
$TD_BIN done "$f_id3" >/dev/null 2>&1

# Test 13: filter by status=todo shows only todo task
local ls_todo
ls_todo=$($TD_BIN ls -s todo 2>&1)
assert_contains "ls -s todo: shows todo task" "Filter task one" "$ls_todo"
# Should NOT contain the doing or done tasks
local ls_todo_no_doing=true
[[ "$ls_todo" == *"Filter task two"* ]] && ls_todo_no_doing=false
assert_eq "ls -s todo: excludes doing task" "true" "$ls_todo_no_doing"

# Test 14: filter by status=doing shows only doing task
local ls_doing
ls_doing=$($TD_BIN ls -s doing 2>&1)
assert_contains "ls -s doing: shows doing task" "Filter task two" "$ls_doing"
local ls_doing_no_todo=true
[[ "$ls_doing" == *"Filter task one"* ]] && ls_doing_no_todo=false
assert_eq "ls -s doing: excludes todo task" "true" "$ls_doing_no_todo"

# Test 15: filter by priority=alta shows only alta task
local ls_alta
ls_alta=$($TD_BIN ls -p alta 2>&1)
assert_contains "ls -p alta: shows alta task" "Filter task one" "$ls_alta"
local ls_alta_no_media=true
[[ "$ls_alta" == *"Filter task two"* ]] && ls_alta_no_media=false
assert_eq "ls -p alta: excludes media task" "true" "$ls_alta_no_media"

# Test 16: combined filter status=todo + priority=alta
local ls_combo
ls_combo=$($TD_BIN ls -s todo -p alta 2>&1)
assert_contains "ls -s todo -p alta: shows matching task" "Filter task one" "$ls_combo"
local ls_combo_no_other=true
[[ "$ls_combo" == *"Filter task two"* ]] && ls_combo_no_other=false
assert_eq "ls -s todo -p alta: excludes non-matching" "true" "$ls_combo_no_other"

# Test 17: combined filter that matches nothing
local ls_empty
ls_empty=$($TD_BIN ls -s done -p alta 2>&1)
assert_contains "ls -s done -p alta: shows empty msg" "No tasks" "$ls_empty"

# Test 18: no filters shows all tasks
local ls_all
ls_all=$($TD_BIN ls 2>&1)
assert_contains "ls no filter: shows task one" "Filter task one" "$ls_all"
assert_contains "ls no filter: shows task two" "Filter task two" "$ls_all"
assert_contains "ls no filter: shows task three" "Filter task three" "$ls_all"

# Test 19: output includes Tags column header
assert_contains "ls output: Tags column header" "Tags" "$ls_all"

# Test 20: output includes tag values
assert_contains "ls output: work tag in output" "work" "$ls_all"
assert_contains "ls output: personal tag in output" "personal" "$ls_all"

# ============================================================
# Summary
# ============================================================

test_summary
