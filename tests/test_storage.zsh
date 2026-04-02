#!/usr/bin/env zsh
# Test suite for _td_storage module
# Covers: STOR-01 (dir structure), STOR-02 (atomic writes), STOR-04 (JXA JSON ops)

source "${0:A:h}/test_helpers.zsh"

# Isolated test data dir (not real ~/.todolist)
TEST_DATA="$(mktemp -d)"
trap "rm -rf '$TEST_DATA'" EXIT INT TERM

# Load modules
TD_DATA="$TEST_DATA"
TD_ROOT="${0:A:h}/.."
fpath=("$TD_ROOT/lib" $fpath)
autoload -Uz _td_core && _td_core
autoload -Uz _td_storage && _td_storage

# ============================================================
# STOR-01: Directory Structure
# ============================================================

printf "\n=== STOR-01: Directory Structure ===\n"

# Test 1: _td_storage_init creates tasks.json
_td_storage_init
assert_eq "init creates tasks.json" "1" "$([ -f "$TD_DATA/lists/default/tasks.json" ] && echo 1 || echo 0)"

# Test 2: _td_storage_init creates config.json
assert_eq "init creates config.json" "1" "$([ -f "$TD_DATA/config.json" ] && echo 1 || echo 0)"

# Test 3: tasks.json contains valid JSON with empty tasks array
local tasks_content
tasks_content="$(cat "$TD_DATA/lists/default/tasks.json")"
assert_contains "tasks.json has tasks array" '"tasks":[]' "$tasks_content"

# Test 4: config.json has active_list=default
local config_content
config_content="$(cat "$TD_DATA/config.json")"
assert_contains "config.json has active_list default" '"active_list":"default"' "$config_content"

# Test 5: _td_storage_init is idempotent
local tasks_file="$TD_DATA/lists/default/tasks.json"
_td_storage_add_task "$tasks_file" "idempotency test task"
_td_storage_init
local after_init
after_init="$(_td_storage_read "$tasks_file" '.tasks.length')"
assert_eq "init is idempotent (preserves tasks)" "1" "$after_init"

# Test 6: _td_storage_list_path returns correct path
local list_path
list_path="$(_td_storage_list_path "work")"
assert_eq "list_path for work" "$TD_DATA/lists/work/tasks.json" "$list_path"

# Test 7: _td_storage_list_path default
local default_path
default_path="$(_td_storage_list_path)"
assert_eq "list_path default" "$TD_DATA/lists/default/tasks.json" "$default_path"

# Test 8: _td_storage_config_path returns correct path
local cfg_path
cfg_path="$(_td_storage_config_path)"
assert_eq "config_path" "$TD_DATA/config.json" "$cfg_path"

# ============================================================
# STOR-02: Atomic Writes
# ============================================================

printf "\n=== STOR-02: Atomic Writes ===\n"

# Test 9: _td_storage_atomic_write creates file with correct content
local atomic_test_file="$TEST_DATA/atomic_test.json"
_td_storage_atomic_write "$atomic_test_file" '{"test":"value"}'
local atomic_content
atomic_content="$(cat "$atomic_test_file")"
assert_eq "atomic_write creates file" '{"test":"value"}' "$atomic_content"

# Test 10: No .tmp.* files remain after modify
_td_storage_modify "$tasks_file" 'data.name = "modified"'
local tmp_count
tmp_count=$(find "$TD_DATA" -name "*.tmp.*" 2>/dev/null | wc -l | tr -d ' ')
assert_eq "no temp files after modify" "0" "$tmp_count"

# Test 11: Failed JXA operation does not corrupt target file
local safe_file="$TEST_DATA/safe_test.json"
printf '{"safe":"data"}\n' > "$safe_file"
_td_storage_modify "$safe_file" 'INVALID JAVASCRIPT %%% SYNTAX ERROR' 2>/dev/null
local safe_content
safe_content="$(cat "$safe_file")"
assert_contains "failed modify preserves file" '"safe":"data"' "$safe_content"

# ============================================================
# STOR-04: JXA JSON Operations
# ============================================================

printf "\n=== STOR-04: JXA JSON Operations ===\n"

# Reset test data for JXA tests
local jxa_file="$TEST_DATA/jxa_test.json"
printf '{"name":"jxa-test","statuses":["todo","done"],"tasks":[]}\n' > "$jxa_file"

# Test 12: _td_storage_read parses JSON and returns full data
local full_read
full_read="$(_td_storage_read "$jxa_file")"
assert_contains "read returns full JSON" '"name":"jxa-test"' "$full_read"

# Test 13: _td_storage_read with query extracts value
local name_read
name_read="$(_td_storage_read "$jxa_file" '.name')"
assert_eq "read with query" '"jxa-test"' "$name_read"

# Test 14: _td_storage_modify transforms data
_td_storage_modify "$jxa_file" 'data.name = "modified-test"'
local modified_name
modified_name="$(_td_storage_read "$jxa_file" '.name')"
assert_eq "modify transforms data" '"modified-test"' "$modified_name"

# Test 15: _td_storage_add_task adds task with all fields
local add_file="$TEST_DATA/add_test.json"
printf '{"name":"add-test","statuses":["todo","doing","done"],"tasks":[]}\n' > "$add_file"
local returned_id
returned_id="$(_td_storage_add_task "$add_file" "Buy groceries")"

local task_read
task_read="$(_td_storage_read "$add_file" '.tasks[0]')"
assert_contains "add_task has text" '"text":"Buy groceries"' "$task_read"
assert_contains "add_task has status" '"status":"todo"' "$task_read"
assert_contains "add_task has priority" '"priority":"medium"' "$task_read"
assert_contains "add_task has tags" '"tags":[]' "$task_read"
assert_contains "add_task has created" '"created"' "$task_read"
assert_contains "add_task has id" '"id"' "$task_read"

# Test 16: _td_storage_add_task returns UUID
assert_contains "add_task returns UUID" "-" "$returned_id"
local uuid_valid
uuid_valid=$(printf '%s' "$returned_id" | grep -cE '^[A-F0-9-]+$' || true)
assert_eq "returned ID matches UUID pattern" "1" "$uuid_valid"

# Test 17: Special characters survive round-trip
local special_file="$TEST_DATA/special_test.json"
printf '{"name":"special","statuses":["todo"],"tasks":[]}\n' > "$special_file"
_td_storage_add_task "$special_file" 'Fix "quotes" & <angles> and $dollars'
local special_text
special_text="$(_td_storage_read "$special_file" '.tasks[0].text')"
assert_contains "special chars: quotes" '"' "$special_text"
assert_contains "special chars: ampersand" '&' "$special_text"
assert_contains "special chars: angle brackets" '<angles>' "$special_text"

# Test 18: _td_storage_read on nonexistent file returns error
_td_storage_read "/nonexistent/file.json" 2>/dev/null
local read_exit=$?
assert_eq "read nonexistent file returns error" "1" "$read_exit"

# Test 19: _td_storage_new_id returns UUID pattern
local new_id
new_id="$(_td_storage_new_id)"
local id_valid
id_valid=$(printf '%s' "$new_id" | grep -cE '^[A-F0-9-]+$' || true)
assert_eq "new_id returns UUID pattern" "1" "$id_valid"

# ============================================================
# Summary
# ============================================================

test_summary
