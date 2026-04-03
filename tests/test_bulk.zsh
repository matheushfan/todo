#!/usr/bin/env zsh
# Tests for td-bulk command (bulk operations: done, move, rm)

source "${0:A:h}/test_helpers.zsh"

# --- Setup ---
setup_bulk_env() {
  export TODOLIST_DATA="$(mktemp -d)"
  export TD_DATA="$TODOLIST_DATA"

  # Create default list with 5 tasks across different statuses
  mkdir -p "$TD_DATA/lists/default"
  printf '{"active_list":"default","version":1}\n' > "$TD_DATA/config.json"

  # Fixed UUIDs for predictable testing
  cat > "$TD_DATA/lists/default/tasks.json" <<'JSON'
{
  "name": "default",
  "statuses": ["todo", "doing", "done"],
  "tasks": [
    {"id":"AAAA1111-0000-0000-0000-000000000001","text":"Task Alpha","status":"todo","priority":"high","tags":[],"created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"},
    {"id":"BBBB2222-0000-0000-0000-000000000002","text":"Task Beta","status":"todo","priority":"medium","tags":[],"created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"},
    {"id":"CCCC3333-0000-0000-0000-000000000003","text":"Task Gamma","status":"doing","priority":"low","tags":[],"created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"},
    {"id":"DDDD4444-0000-0000-0000-000000000004","text":"Task Delta","status":"doing","priority":"high","tags":[],"created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"},
    {"id":"EEEE5555-0000-0000-0000-000000000005","text":"Task Epsilon","status":"done","priority":"medium","tags":[],"created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"}
  ]
}
JSON
}

teardown_bulk_env() {
  rm -rf "$TODOLIST_DATA"
  unset TODOLIST_DATA TD_DATA
}

# Helper to read task status from JSON
get_task_status() {
  local tasks_file="$1"
  local task_id="$2"
  TASK_ID="$task_id" JSON_DATA="$(cat "$tasks_file")" osascript -l JavaScript -e '
    function run() {
      var env = $.NSProcessInfo.processInfo.environment;
      var data = JSON.parse(env.objectForKey("JSON_DATA").js);
      var tid = env.objectForKey("TASK_ID").js;
      var t = data.tasks.find(function(x) { return x.id === tid; });
      return t ? t.status : "NOT_FOUND";
    }
  ' 2>/dev/null
}

# Helper to count tasks in file
count_tasks() {
  local tasks_file="$1"
  JSON_DATA="$(cat "$tasks_file")" osascript -l JavaScript -e '
    function run() {
      var env = $.NSProcessInfo.processInfo.environment;
      var data = JSON.parse(env.objectForKey("JSON_DATA").js);
      return "" + data.tasks.length;
    }
  ' 2>/dev/null
}

# ========================
# Test 1: bulk done with 2 IDs
# ========================
echo "=== Test: bulk done with 2 IDs ==="
setup_bulk_env
output=$($TD_BIN bulk done AAAA1111 BBBB2222 2>&1)
rc=$?
tasks_file="$TD_DATA/lists/default/tasks.json"

assert_exit_code "bulk done exits 0" "0" "$rc"
s1=$(get_task_status "$tasks_file" "AAAA1111-0000-0000-0000-000000000001")
s2=$(get_task_status "$tasks_file" "BBBB2222-0000-0000-0000-000000000002")
assert_eq "task Alpha is done" "done" "$s1"
assert_eq "task Beta is done" "done" "$s2"
assert_contains "reports count" "2" "$output"
teardown_bulk_env

# ========================
# Test 2: bulk move with 2 IDs
# ========================
echo "=== Test: bulk move with 2 IDs ==="
setup_bulk_env
output=$($TD_BIN bulk move doing AAAA1111 BBBB2222 2>&1)
rc=$?
tasks_file="$TD_DATA/lists/default/tasks.json"

assert_exit_code "bulk move exits 0" "0" "$rc"
s1=$(get_task_status "$tasks_file" "AAAA1111-0000-0000-0000-000000000001")
s2=$(get_task_status "$tasks_file" "BBBB2222-0000-0000-0000-000000000002")
assert_eq "task Alpha is doing" "doing" "$s1"
assert_eq "task Beta is doing" "doing" "$s2"
assert_contains "reports count" "2" "$output"
teardown_bulk_env

# ========================
# Test 3: bulk rm with 2 IDs
# ========================
echo "=== Test: bulk rm with 2 IDs ==="
setup_bulk_env
output=$($TD_BIN bulk rm AAAA1111 BBBB2222 2>&1)
rc=$?
tasks_file="$TD_DATA/lists/default/tasks.json"

assert_exit_code "bulk rm exits 0" "0" "$rc"
count=$(count_tasks "$tasks_file")
assert_eq "3 tasks remain after removing 2" "3" "$count"
assert_contains "reports count" "2" "$output"
teardown_bulk_env

# ========================
# Test 4: bulk done --all
# ========================
echo "=== Test: bulk done --all ==="
setup_bulk_env
output=$($TD_BIN bulk done --all 2>&1)
rc=$?
tasks_file="$TD_DATA/lists/default/tasks.json"

assert_exit_code "bulk done --all exits 0" "0" "$rc"
s1=$(get_task_status "$tasks_file" "AAAA1111-0000-0000-0000-000000000001")
s2=$(get_task_status "$tasks_file" "BBBB2222-0000-0000-0000-000000000002")
s3=$(get_task_status "$tasks_file" "CCCC3333-0000-0000-0000-000000000003")
s4=$(get_task_status "$tasks_file" "DDDD4444-0000-0000-0000-000000000004")
assert_eq "task Alpha is done" "done" "$s1"
assert_eq "task Beta is done" "done" "$s2"
assert_eq "task Gamma is done" "done" "$s3"
assert_eq "task Delta is done" "done" "$s4"
assert_contains "reports count" "5" "$output"
teardown_bulk_env

# ========================
# Test 5: bulk move --status filter
# ========================
echo "=== Test: bulk move doing --status todo ==="
setup_bulk_env
output=$($TD_BIN bulk move doing --status todo 2>&1)
rc=$?
tasks_file="$TD_DATA/lists/default/tasks.json"

assert_exit_code "bulk move --status exits 0" "0" "$rc"
# The 2 todo tasks should now be doing
s1=$(get_task_status "$tasks_file" "AAAA1111-0000-0000-0000-000000000001")
s2=$(get_task_status "$tasks_file" "BBBB2222-0000-0000-0000-000000000002")
# The doing tasks stay doing
s3=$(get_task_status "$tasks_file" "CCCC3333-0000-0000-0000-000000000003")
assert_eq "task Alpha moved to doing" "doing" "$s1"
assert_eq "task Beta moved to doing" "doing" "$s2"
assert_eq "task Gamma still doing" "doing" "$s3"
assert_contains "reports count" "2" "$output"
teardown_bulk_env

# ========================
# Test 6: bulk rm --status done
# ========================
echo "=== Test: bulk rm --status done ==="
setup_bulk_env
output=$($TD_BIN bulk rm --status done 2>&1)
rc=$?
tasks_file="$TD_DATA/lists/default/tasks.json"

assert_exit_code "bulk rm --status exits 0" "0" "$rc"
count=$(count_tasks "$tasks_file")
assert_eq "4 tasks remain after removing 1 done" "4" "$count"
# Epsilon was the only done task
s5=$(get_task_status "$tasks_file" "EEEE5555-0000-0000-0000-000000000005")
assert_eq "Epsilon removed" "NOT_FOUND" "$s5"
teardown_bulk_env

# ========================
# Test 7: Ambiguous ID aborts entire operation
# ========================
echo "=== Test: ambiguous ID aborts entire bulk operation ==="
export TODOLIST_DATA="$(mktemp -d)"
export TD_DATA="$TODOLIST_DATA"
mkdir -p "$TD_DATA/lists/default"
printf '{"active_list":"default","version":1}\n' > "$TD_DATA/config.json"
# Two tasks sharing prefix "ABAB"
cat > "$TD_DATA/lists/default/tasks.json" <<'JSON'
{
  "name": "default",
  "statuses": ["todo", "doing", "done"],
  "tasks": [
    {"id":"ABAB1111-0000-0000-0000-000000000001","text":"First","status":"todo","priority":"medium","tags":[],"created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"},
    {"id":"ABAB2222-0000-0000-0000-000000000002","text":"Second","status":"todo","priority":"medium","tags":[],"created":"2026-01-01T00:00:00Z","updated":"2026-01-01T00:00:00Z"}
  ]
}
JSON
tasks_file="$TD_DATA/lists/default/tasks.json"
output=$($TD_BIN bulk done ABAB 2>&1)
rc=$?
assert_exit_code "ambiguous ID returns error" "1" "$rc"
# Both tasks should still be todo (no partial execution)
s1=$(get_task_status "$tasks_file" "ABAB1111-0000-0000-0000-000000000001")
s2=$(get_task_status "$tasks_file" "ABAB2222-0000-0000-0000-000000000002")
assert_eq "first task unchanged" "todo" "$s1"
assert_eq "second task unchanged" "todo" "$s2"
teardown_bulk_env

# ========================
# Test 8: Invalid status in bulk move
# ========================
echo "=== Test: invalid status in bulk move ==="
setup_bulk_env
output=$($TD_BIN bulk move nonexistent AAAA1111 2>&1)
rc=$?
assert_exit_code "invalid status returns error" "1" "$rc"
assert_contains "error mentions invalid" "Invalid status" "$output"
teardown_bulk_env

# ========================
# Test 9: No args shows usage error
# ========================
echo "=== Test: no args shows usage ==="
setup_bulk_env
output=$($TD_BIN bulk 2>&1)
rc=$?
assert_exit_code "no args returns error" "1" "$rc"
assert_contains "shows usage" "Usage" "$output"
teardown_bulk_env

# ========================
# Test 10: Reports count on success
# ========================
echo "=== Test: reports count on success ==="
setup_bulk_env
output=$($TD_BIN bulk rm AAAA1111 BBBB2222 CCCC3333 2>&1)
rc=$?
assert_exit_code "bulk rm 3 items exits 0" "0" "$rc"
assert_contains "reports 3" "3" "$output"
teardown_bulk_env

# ========================
# Test 11: bulk done on already-done tasks (idempotent)
# ========================
echo "=== Test: bulk done on already-done tasks ==="
setup_bulk_env
output=$($TD_BIN bulk done EEEE5555 2>&1)
rc=$?
tasks_file="$TD_DATA/lists/default/tasks.json"
assert_exit_code "done on already-done exits 0" "0" "$rc"
s5=$(get_task_status "$tasks_file" "EEEE5555-0000-0000-0000-000000000005")
assert_eq "Epsilon still done" "done" "$s5"
teardown_bulk_env

# ========================
# Test 12: bulk rm --all on empty list
# ========================
echo "=== Test: bulk rm --all on empty list ==="
export TODOLIST_DATA="$(mktemp -d)"
export TD_DATA="$TODOLIST_DATA"
mkdir -p "$TD_DATA/lists/default"
printf '{"active_list":"default","version":1}\n' > "$TD_DATA/config.json"
cat > "$TD_DATA/lists/default/tasks.json" <<'JSON'
{
  "name": "default",
  "statuses": ["todo", "doing", "done"],
  "tasks": []
}
JSON
output=$($TD_BIN bulk rm --all 2>&1)
rc=$?
assert_exit_code "rm --all on empty exits 0" "0" "$rc"
assert_contains "reports 0" "0" "$output"
teardown_bulk_env

# ========================
# Test 13: Mixed valid/invalid IDs aborts
# ========================
echo "=== Test: mixed valid/invalid IDs aborts ==="
setup_bulk_env
tasks_file="$TD_DATA/lists/default/tasks.json"
output=$($TD_BIN bulk done AAAA1111 ZZZZZZZZ 2>&1)
rc=$?
assert_exit_code "mixed IDs returns error" "1" "$rc"
# First task should NOT be changed since operation aborts before modifying
s1=$(get_task_status "$tasks_file" "AAAA1111-0000-0000-0000-000000000001")
assert_eq "task Alpha unchanged" "todo" "$s1"
teardown_bulk_env

# --- Summary ---
test_summary
