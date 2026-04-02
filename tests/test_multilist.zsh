#!/usr/bin/env zsh
# Test suite for multi-list management
# Covers: LIST-01 (create lists), LIST-02 (switch lists), LIST-03 (default list)

source "${0:A:h}/test_helpers.zsh"

# Isolated test data dir
TEST_DATA="$(mktemp -d)"
trap "rm -rf '$TEST_DATA'" EXIT INT TERM

# Load modules
TD_DATA="$TEST_DATA"
TD_ROOT="${0:A:h}/.."
fpath=("$TD_ROOT/lib" "$TD_ROOT/commands" $fpath)
autoload -Uz _td_core && _td_core
autoload -Uz _td_storage && _td_storage

# ============================================================
# LIST-03: Default List / Active List Resolution
# ============================================================

printf "\n=== LIST-03: Active List Resolution ===\n"

# Setup: init creates config.json with active_list:"default"
_td_storage_init

# Test 1: _td_storage_active_list reads "default" from config.json
local active1
active1="$(_td_storage_active_list)"
assert_eq "active_list reads default from config" "default" "$active1"

# Test 2: _td_storage_active_list falls back to "default" when config.json missing
rm -f "$TD_DATA/config.json"
local active2
active2="$(_td_storage_active_list)"
assert_eq "active_list fallback when config missing" "default" "$active2"

# Test 3: _td_storage_active_list reads updated value
# Recreate config with active_list set to "work"
printf '{"active_list":"work","version":1}\n' > "$TD_DATA/config.json"
local active3
active3="$(_td_storage_active_list)"
assert_eq "active_list reads work after update" "work" "$active3"

# Test 4: _td_storage_list_path (no args) uses active list from config
printf '{"active_list":"mylist","version":1}\n' > "$TD_DATA/config.json"
local path4
path4="$(_td_storage_list_path)"
assert_eq "list_path no args uses active list" "$TD_DATA/lists/mylist/tasks.json" "$path4"

# Test 5: _td_storage_list_path (explicit arg) unchanged
local path5
path5="$(_td_storage_list_path "explicit")"
assert_eq "list_path explicit arg unchanged" "$TD_DATA/lists/explicit/tasks.json" "$path5"

# Test 6: _td_storage_init recreates config.json if missing but default dir exists
# Reset: config exists, default dir exists
printf '{"active_list":"default","version":1}\n' > "$TD_DATA/config.json"
# Delete config only
rm -f "$TD_DATA/config.json"
# default dir still exists from earlier _td_storage_init
_td_storage_init
assert_eq "init recreates config.json when missing" "1" "$([ -f "$TD_DATA/config.json" ] && echo 1 || echo 0)"

# ============================================================
# LIST-01: Create Lists
# ============================================================

printf "\n=== LIST-01: Create Lists ===\n"

# Reset to clean state
rm -rf "$TEST_DATA"/*
TD_DATA="$TEST_DATA"
_td_storage_init

# Test 7: List create creates directory + tasks.json
mkdir -p "$TD_DATA/lists/work"
printf '{"name":"work","statuses":["todo","doing","done"],"tasks":[]}\n' > "$TD_DATA/lists/work/tasks.json"
assert_eq "create makes tasks.json" "1" "$([ -f "$TD_DATA/lists/work/tasks.json" ] && echo 1 || echo 0)"

# Verify structure of created tasks.json
local work_content
work_content="$(cat "$TD_DATA/lists/work/tasks.json")"
assert_contains "created list has name" '"name":"work"' "$work_content"
assert_contains "created list has statuses" '"statuses"' "$work_content"
assert_contains "created list has empty tasks" '"tasks":[]' "$work_content"

# ============================================================
# LIST-02: Switch Lists
# ============================================================

printf "\n=== LIST-02: Switch Lists ===\n"

# Test 10: Switch updates active_list in config.json
export NEW_LIST="work"
_td_storage_modify "$(_td_storage_config_path)" '
  var env = $.NSProcessInfo.processInfo.environment;
  data.active_list = env.objectForKey("NEW_LIST").js;
'
unset NEW_LIST
local switched
switched="$(_td_storage_active_list)"
assert_eq "switch updates active_list" "work" "$switched"

# ============================================================
# Cross-List Isolation
# ============================================================

printf "\n=== Cross-List Isolation ===\n"

# Test 11: Tasks added to one list don't appear in another
local work_file="$TD_DATA/lists/work/tasks.json"
local default_file="$TD_DATA/lists/default/tasks.json"

_td_storage_add_task "$work_file" "work task 1"
local work_count
work_count="$(_td_storage_read "$work_file" '.tasks.length')"
local default_count
default_count="$(_td_storage_read "$default_file" '.tasks.length')"

assert_eq "work list has 1 task" "1" "$work_count"
assert_eq "default list has 0 tasks" "0" "$default_count"

# ============================================================
# Integration Tests (CLI-level via $TD_BIN)
# ============================================================

printf "\n=== Integration: td-list command ===\n"

# Fresh isolated environment for integration tests
INT_DATA="$(mktemp -d)"
trap "rm -rf '$TEST_DATA' '$INT_DATA'" EXIT INT TERM
export TODOLIST_DATA="$INT_DATA"

# Test 14: todo list create work creates tasks.json
local create_out
create_out="$(zsh "$TD_BIN" list create work 2>&1)"
assert_eq "CLI create work succeeds" "0" "$?"
assert_eq "CLI create work tasks.json exists" "1" "$([ -f "$INT_DATA/lists/work/tasks.json" ] && echo 1 || echo 0)"
assert_contains "CLI create output" "Created list 'work'" "$create_out"

# Test 15: todo list create work again returns error (duplicate)
local dup_out
dup_out="$(zsh "$TD_BIN" list create work 2>&1)"
local dup_exit=$?
assert_eq "CLI create duplicate exits 1" "1" "$dup_exit"
assert_contains "CLI create duplicate error" "already exists" "$dup_out"

# Test 16: todo list create "bad name" returns error (invalid chars)
local bad_out
bad_out="$(zsh "$TD_BIN" list create "bad name" 2>&1)"
local bad_exit=$?
assert_eq "CLI create invalid name exits 1" "1" "$bad_exit"
assert_contains "CLI create invalid name error" "Invalid list name" "$bad_out"

# Test 17: todo list switch work changes active_list
local switch_out
switch_out="$(zsh "$TD_BIN" list switch work 2>&1)"
assert_eq "CLI switch work succeeds" "0" "$?"
assert_contains "CLI switch output" "Switched to list 'work'" "$switch_out"

# Verify config.json updated
local cfg_active
cfg_active=$(JSON_DATA="$(cat "$INT_DATA/config.json")" osascript -l JavaScript -e '
  function run() {
    var data = JSON.parse($.NSProcessInfo.processInfo.environment.objectForKey("JSON_DATA").js);
    return data.active_list;
  }
' 2>/dev/null)
assert_eq "CLI switch updated config" "work" "$cfg_active"

# Test 18: todo list switch nonexistent returns error
local noswitch_out
noswitch_out="$(zsh "$TD_BIN" list switch nonexistent 2>&1)"
local noswitch_exit=$?
assert_eq "CLI switch nonexistent exits 1" "1" "$noswitch_exit"
assert_contains "CLI switch nonexistent error" "does not exist" "$noswitch_out"

# Test 19: todo add after switching adds to work list, not default
zsh "$TD_BIN" add "task in work list" >/dev/null 2>&1
local work_tasks
work_tasks="$(cat "$INT_DATA/lists/work/tasks.json")"
assert_contains "CLI add goes to active list" "task in work list" "$work_tasks"
local default_tasks
default_tasks="$(cat "$INT_DATA/lists/default/tasks.json")"
local default_has_work_task=0
[[ "$default_tasks" == *"task in work list"* ]] && default_has_work_task=1
assert_eq "CLI add not in default list" "0" "$default_has_work_task"

# Test 20: todo list output contains active marker
local list_out
list_out="$(zsh "$TD_BIN" list 2>&1)"
assert_contains "CLI list shows active marker" "* work (active)" "$list_out"
assert_contains "CLI list shows default" "default" "$list_out"

# Test 21: todo list shows task counts
assert_contains "CLI list shows task count for work" "1 tasks" "$list_out"
assert_contains "CLI list shows task count for default" "0 tasks" "$list_out"

# Test 22: Cross-list isolation via CLI
zsh "$TD_BIN" list switch default >/dev/null 2>&1
local ls_default
ls_default="$(zsh "$TD_BIN" ls 2>&1)"
local has_work_task=0
[[ "$ls_default" == *"task in work list"* ]] && has_work_task=1
assert_eq "CLI cross-list isolation: work task not in default ls" "0" "$has_work_task"

unset TODOLIST_DATA

# ============================================================
# Summary
# ============================================================

test_summary
