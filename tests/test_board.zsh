#!/usr/bin/env zsh
# Test: kanban board rendering
# Tests _td_board_render (side-by-side) and _td_board_stacked (narrow fallback)

source "${0:A:h}/test_helpers.zsh"

TD_ROOT="${0:A:h}/.."
fpath=("$TD_ROOT/lib" "$TD_ROOT/commands" $fpath)

# Load libs
autoload -Uz _td_core && _td_core
autoload -Uz _td_storage && _td_storage

# Disable colors for predictable assertions
TD_COLOR_ENABLED=0
autoload -Uz _td_color && _td_color
autoload -Uz _td_board && _td_board

# --- Helper: create test data ---
setup_board_data() {
  local tmpdir=$(mktemp -d)
  typeset -g TD_DATA="$tmpdir"
  _td_storage_init

  local tasks_file="$(_td_storage_list_path)"

  # Add tasks across statuses
  TASK_TAGS="" _td_storage_add_task "$tasks_file" "Design homepage" "todo" "high" > /dev/null
  TASK_TAGS="" _td_storage_add_task "$tasks_file" "Write tests" "todo" "medium" > /dev/null
  TASK_TAGS="" _td_storage_add_task "$tasks_file" "Code review" "doing" "low" > /dev/null
  TASK_TAGS="" _td_storage_add_task "$tasks_file" "Deploy app" "done" "high" > /dev/null

  printf '%s' "$tasks_file"
}

# --- Test 1: Column headers (UPPERCASE, bold cyan) ---
echo "=== Board: Column Headers ==="

tasks_file=$(setup_board_data)
output=$(COLUMNS=120 _td_board_render "$tasks_file" 2>&1)

assert_contains "header: TODO present" "TODO" "$output"
assert_contains "header: DOING present" "DOING" "$output"
assert_contains "header: DONE present" "DONE" "$output"

# --- Test 2: Tasks under correct columns ---
echo ""
echo "=== Board: Tasks in Correct Columns ==="

assert_contains "task: Design homepage" "Design homepage" "$output"
assert_contains "task: Write tests" "Write tests" "$output"
assert_contains "task: Code review" "Code review" "$output"
assert_contains "task: Deploy app" "Deploy app" "$output"

# --- Test 3: Column separator ---
echo ""
echo "=== Board: Column Separator ==="

assert_contains "separator: | present" "|" "$output"

# --- Test 4: Priority indicators ---
echo ""
echo "=== Board: Priority Indicators ==="

assert_contains "priority: ! for high" "!" "$output"
assert_contains "priority: ~ for medium" "~" "$output"
assert_contains "priority: . for low" "." "$output"

# --- Test 5: Text truncation ---
echo ""
echo "=== Board: Text Truncation ==="

tmpdir2=$(mktemp -d)
TD_DATA="$tmpdir2"
_td_storage_init
tasks_file2="$(_td_storage_list_path)"
TASK_TAGS="" _td_storage_add_task "$tasks_file2" "This is a very long task title that should definitely be truncated when displayed" "todo" "medium" > /dev/null

trunc_output=$(COLUMNS=60 _td_board_render "$tasks_file2" 2>&1)
assert_contains "truncation: ~ marker present" "~" "$trunc_output"

# --- Test 6: Stacked fallback (COLUMNS=40, 3 statuses -> col_width < 20) ---
echo ""
echo "=== Board: Stacked Fallback ==="

stacked_output=$(COLUMNS=40 _td_board_render "$tasks_file" 2>&1)

# Stacked mode should NOT have | separators between columns
# But it should still have the status names
assert_contains "stacked: TODO present" "TODO" "$stacked_output"
assert_contains "stacked: DOING present" "DOING" "$stacked_output"
assert_contains "stacked: DONE present" "DONE" "$stacked_output"

# --- Test 7: Stacked view shows tasks vertically ---
echo ""
echo "=== Board: Stacked Tasks Vertical ==="

assert_contains "stacked: Design homepage" "Design homepage" "$stacked_output"
assert_contains "stacked: Code review" "Code review" "$stacked_output"
assert_contains "stacked: Deploy app" "Deploy app" "$stacked_output"

# --- Test 8: Empty column handling ---
echo ""
echo "=== Board: Empty Column ==="

tmpdir3=$(mktemp -d)
TD_DATA="$tmpdir3"
_td_storage_init
tasks_file3="$(_td_storage_list_path)"

# Add tasks only in todo and done (doing is empty)
TASK_TAGS="" _td_storage_add_task "$tasks_file3" "First task" "todo" "medium" > /dev/null
TASK_TAGS="" _td_storage_add_task "$tasks_file3" "Completed task" "done" "high" > /dev/null

empty_col_output=$(COLUMNS=120 _td_board_render "$tasks_file3" 2>&1)

# Board should still render without misalignment
assert_contains "empty col: TODO header" "TODO" "$empty_col_output"
assert_contains "empty col: DOING header" "DOING" "$empty_col_output"
assert_contains "empty col: DONE header" "DONE" "$empty_col_output"
assert_contains "empty col: has separator" "|" "$empty_col_output"

# --- Test 9: Board with no tasks ---
echo ""
echo "=== Board: No Tasks ==="

tmpdir4=$(mktemp -d)
TD_DATA="$tmpdir4"
_td_storage_init
tasks_file4="$(_td_storage_list_path)"

no_tasks_output=$(COLUMNS=120 _td_board_render "$tasks_file4" 2>&1)
# Should show a separator row (===) with empty board
# Verify it doesn't crash and shows headers
assert_contains "no tasks: TODO header" "TODO" "$no_tasks_output"

# Cleanup
rm -rf "$tmpdir2" "$tmpdir3" "$tmpdir4"
[[ -n "${tasks_file}" ]] && rm -rf "${tasks_file:h:h:h}"

echo ""
test_summary
