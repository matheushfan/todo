#!/usr/bin/env zsh
# Test color library and colored output

source "${0:A:h}/test_helpers.zsh"

# Setup temp data dir
TEST_DATA=$(mktemp -d)
export TODOLIST_DATA="$TEST_DATA"
trap 'rm -rf "$TEST_DATA"' EXIT

# Setup autoload paths
local td_root="${0:A:h}/.."
fpath=("$td_root/lib" "$td_root/commands" $fpath)

# Load core libs
autoload -Uz _td_core && _td_core
autoload -Uz _td_storage && _td_storage

# Force colors enabled for unit tests (set BEFORE loading _td_color)
typeset -g TD_COLOR_ENABLED=1
autoload -Uz _td_color && _td_color

# ========== Unit Tests: _td_strip_ansi ==========

printf "\n--- _td_strip_ansi ---\n"

# Plain text unchanged
local result
result=$(_td_strip_ansi "hello world")
assert_eq "strip_ansi: plain text unchanged" "hello world" "$result"

# Single color code removed
local red=$'\033[0;31m'
local reset=$'\033[0m'
result=$(_td_strip_ansi "${red}alta${reset}")
assert_eq "strip_ansi: single color code" "alta" "$result"

# Combined codes removed (bold+color)
local bold_red=$'\033[1;31m'
result=$(_td_strip_ansi "${bold_red}alta${reset}")
assert_eq "strip_ansi: combined bold+color" "alta" "$result"

# Nested codes
local bold=$'\033[1m'
local cyan=$'\033[0;36m'
result=$(_td_strip_ansi "${bold}${cyan}text${reset}")
assert_eq "strip_ansi: nested codes" "text" "$result"

# Dim code
local dim=$'\033[2m'
result=$(_td_strip_ansi "${dim}tags${reset}")
assert_eq "strip_ansi: dim code" "tags" "$result"

# ========== Unit Tests: _td_visible_len ==========

printf "\n--- _td_visible_len ---\n"

local colored_alta="${red}alta${reset}"
local vlen
vlen=$(_td_visible_len "$colored_alta")
assert_eq "visible_len: red 'alta' = 4" "4" "$vlen"

vlen=$(_td_visible_len "plain")
assert_eq "visible_len: plain 'plain' = 5" "5" "$vlen"

# ========== Unit Tests: _td_colorize ==========

printf "\n--- _td_colorize ---\n"

local colorized
colorized=$(_td_colorize red "alta")
assert_contains "colorize: contains color code" $'\033[0;31m' "$colorized"
assert_contains "colorize: contains reset" $'\033[0m' "$colorized"
assert_contains "colorize: contains text" "alta" "$colorized"

# ========== Unit Tests: _td_printf_colored ==========

printf "\n--- _td_printf_colored ---\n"

local padded
padded=$(_td_printf_colored "${red}alta${reset}" 10)
local stripped
stripped=$(_td_strip_ansi "$padded")
# Visible width should be 10 (4 chars + 6 spaces)
assert_eq "printf_colored: visible width is 10" "10" "${#stripped}"

# ========== Unit Tests: TD_COLORS array (enabled) ==========

printf "\n--- TD_COLORS (enabled) ---\n"

assert_contains "TD_COLORS[red] non-empty when enabled" $'\033' "${TD_COLORS[red]}"

# ========== Unit Tests: TD_PRIORITY_COLORS ==========

printf "\n--- TD_PRIORITY_COLORS ---\n"

assert_eq "priority alta -> red" "${TD_COLORS[red]}" "${TD_PRIORITY_COLORS[alta]}"
assert_eq "priority media -> yellow" "${TD_COLORS[yellow]}" "${TD_PRIORITY_COLORS[media]}"
assert_eq "priority baixa -> green" "${TD_COLORS[green]}" "${TD_PRIORITY_COLORS[baixa]}"

# ========== Unit Tests: Piped output (TD_COLOR_ENABLED=0) ==========

printf "\n--- Piped mode (disabled) ---\n"

# Re-initialize with colors disabled
typeset -g TD_COLOR_ENABLED=0
_td_color

assert_eq "TD_COLORS[red] empty when disabled" "" "${TD_COLORS[red]}"
assert_eq "TD_COLORS[cyan] empty when disabled" "" "${TD_COLORS[cyan]}"
assert_eq "TD_COLORS[bold] empty when disabled" "" "${TD_COLORS[bold]}"
assert_eq "TD_COLORS[reset] empty when disabled" "" "${TD_COLORS[reset]}"

# Re-enable for remaining tests
typeset -g TD_COLOR_ENABLED=1
_td_color

# ========== Integration: Piped td-ls has no escape codes ==========

printf "\n--- Integration: piped output ---\n"

# Create a list and add a task
$TD_BIN add "Color test task" 2>&1 >/dev/null

# Pipe td-ls through cat -- should strip colors via TTY detection
local piped_output
piped_output=$($TD_BIN ls 2>&1 | cat)
if [[ "$piped_output" != *$'\033'* ]]; then
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  printf "  PASS: piped td-ls has no escape codes\n"
else
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf "  FAIL: piped td-ls has no escape codes\n    output contains escape sequences\n"
fi

# ========== Integration: td-ls header ==========

printf "\n--- Integration: td-ls header ---\n"

local ls_output
ls_output=$($TD_BIN ls 2>&1 | cat)
assert_contains "td-ls header has ID" "ID" "$ls_output"
assert_contains "td-ls header has Status" "Status" "$ls_output"
assert_contains "td-ls header has Priority" "Priority" "$ls_output"
assert_contains "td-ls header has Tags" "Tags" "$ls_output"
assert_contains "td-ls header has Title" "Title" "$ls_output"

# ========== Integration: td-ls with alta task shows alta in output ==========

printf "\n--- Integration: td-ls alta task ---\n"

$TD_BIN add "Alta priority task" -p alta 2>&1 >/dev/null
ls_output=$($TD_BIN ls 2>&1 | cat)
local stripped_output
stripped_output=$(_td_strip_ansi "$ls_output")
assert_contains "td-ls stripped output contains alta" "alta" "$stripped_output"

test_summary
