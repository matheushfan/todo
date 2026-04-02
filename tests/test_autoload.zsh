#!/usr/bin/env zsh
source "${0:A:h}/test_helpers.zsh"
printf "=== Autoload Tests ===\n"

TD_ROOT="${0:A:h}/.."

# Test 1: fpath directories exist
assert_eq "lib dir exists" "0" "$([[ -d "$TD_ROOT/lib" ]]; echo $?)"
assert_eq "commands dir exists" "0" "$([[ -d "$TD_ROOT/commands" ]]; echo $?)"

# Test 2: Entry point uses autoload (not source)
entry=$(cat "$TD_ROOT/bin/todo")
assert_contains "entry uses autoload" "autoload -Uz" "$entry"
# Verify no source commands for module loading
source_count=$(grep -c "^[[:space:]]*source " "$TD_ROOT/bin/todo" 2>/dev/null)
[[ -z "$source_count" ]] && source_count=0
assert_eq "no source commands in entry" "0" "$source_count"

# Test 3: Command files exist in commands/
assert_eq "td-help exists" "0" "$([[ -f "$TD_ROOT/commands/td-help" ]]; echo $?)"
assert_eq "td-version exists" "0" "$([[ -f "$TD_ROOT/commands/td-version" ]]; echo $?)"

# Test 4: Lib files exist in lib/
assert_eq "_td_core exists" "0" "$([[ -f "$TD_ROOT/lib/_td_core" ]]; echo $?)"
assert_eq "_td_help exists" "0" "$([[ -f "$TD_ROOT/lib/_td_help" ]]; echo $?)"

# Test 5: Command files do NOT wrap in function definition (autoload convention)
td_help_content=$(cat "$TD_ROOT/commands/td-help")
no_func_wrap=$(echo "$td_help_content" | grep -c "^td-help()")
[[ -z "$no_func_wrap" ]] && no_func_wrap=0
assert_eq "td-help not function-wrapped" "0" "$no_func_wrap"

# Test 6: Entry point is executable
assert_eq "bin/todo is executable" "0" "$([[ -x "$TD_ROOT/bin/todo" ]]; echo $?)"

# Test 7: Shebang is zsh
shebang=$(head -1 "$TD_ROOT/bin/todo")
assert_contains "shebang is zsh" "zsh" "$shebang"

test_summary
