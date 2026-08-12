#!/usr/bin/env zsh
# Tests for the raw-ANSI interactive board.
#
# NOTHING HERE TOUCHES A TERMINAL. Key decoding is driven by bytes through a
# pipe, layout is pure arithmetic, and frame composition is a pure function of
# state. That is the whole reason _td_tui_draw was split from _td_tui: the
# visual surface is verifiable without ever allocating a tty.

source "${0:A:h}/test_helpers.zsh"

TD_ROOT="${0:A:h}/.."
fpath=("$TD_ROOT/lib" "$TD_ROOT/commands" $fpath)

autoload -Uz _td_core     && _td_core
autoload -Uz _td_ui       && _td_ui
autoload -Uz _td_key      && _td_key
autoload -Uz _td_layout   && _td_layout
autoload -Uz _td_tui_draw && _td_tui_draw

TD_COLOR_DEPTH=24 LANG=pt_BR.UTF-8 _td_ui_init always

# ===========================================================================
printf "\n--- key decoding (bytes through a pipe, no terminal) ---\n"
# ===========================================================================
key_of() {  # key_of <printf-escaped bytes> -> first decoded key name
  printf "$1" | ( _td_key_read; print -r -- "$REPLY" )
}

assert_eq "plain letter"      "j"         "$(key_of 'j')"
assert_eq "space"             "Space"     "$(key_of ' ')"
assert_eq "enter"             "Enter"     "$(key_of '\r')"
assert_eq "tab"               "Tab"       "$(key_of '\t')"
assert_eq "backspace"         "Backspace" "$(key_of '\177')"
assert_eq "ctrl-d"            "C-d"       "$(key_of '\004')"
assert_eq "ctrl-l"            "C-l"       "$(key_of '\014')"

assert_eq "arrow up (CSI)"    "Up"        "$(key_of '\033[A')"
assert_eq "arrow down (CSI)"  "Down"      "$(key_of '\033[B')"
assert_eq "arrow right"       "Right"     "$(key_of '\033[C')"
assert_eq "arrow left"        "Left"      "$(key_of '\033[D')"
assert_eq "arrow up (SS3)"    "Up"        "$(key_of '\033OA')"
assert_eq "home"              "Home"      "$(key_of '\033[H')"
assert_eq "end via tilde"     "End"       "$(key_of '\033[4~')"
assert_eq "page down"         "PgDn"      "$(key_of '\033[6~')"
assert_eq "page up"           "PgUp"      "$(key_of '\033[5~')"
assert_eq "delete"            "Delete"    "$(key_of '\033[3~')"
assert_eq "shift-tab"         "S-Tab"     "$(key_of '\033[Z')"
assert_eq "shift-up"          "S-Up"      "$(key_of '\033[1;2A')"
assert_eq "ctrl-up"           "C-Up"      "$(key_of '\033[1;5A')"
assert_eq "alt-x"             "M-x"       "$(key_of '\033x')"

# A lone ESC and the start of a sequence are only distinguishable by timing.
assert_eq "lone escape"       "Escape"    "$(key_of '\033')"

# Unknown sequences must degrade to something inert, never to a random action.
assert_contains "unknown CSI is inert" "CSI-" "$(key_of '\033[99Y')"

printf "\n--- SGR mouse decoding ---\n"
mouse_out=$(printf '\033[<0;12;7M' | ( _td_key_read; print -r -- "$REPLY $TD_MOUSE_B $TD_MOUSE_X $TD_MOUSE_Y" ))
assert_eq "mouse press decodes button and position" "MouseDown 0 12 7" "$mouse_out"

# ===========================================================================
printf "\n--- layout arithmetic (pure, no terminal) ---\n"
# ===========================================================================
assert_eq "80x25 / 3 statuses -> board" "0" "$(_td_layout_compute 80 25 3 1; echo $?)"
_td_layout_compute 80 25 3 1
assert_eq "  mode"        "board"      "$TD_L_MODE"
assert_eq "  column widths" "26 26 26" "${TD_L_COLW[*]}"
assert_eq "  columns sum to the full width" "80" \
  "$(( ${TD_L_COLW[1]} + ${TD_L_COLW[2]} + ${TD_L_COLW[3]} + 2 ))"
assert_eq "  task rows"   "19"         "$TD_L_ROWS"
assert_eq "  chrome"      "6"          "$TD_L_CHROME"

_td_layout_compute 100 30 3 1
assert_eq "100x30 distributes the remainder left" "33 33 32" "${TD_L_COLW[*]}"
assert_eq "100x30 sums to full width" "100" \
  "$(( ${TD_L_COLW[1]} + ${TD_L_COLW[2]} + ${TD_L_COLW[3]} + 2 ))"

_td_layout_compute 44 25 3 1
assert_eq "44 cols / 3 statuses -> list mode" "list" "$TD_L_MODE"

_td_layout_compute 64 25 2 1
assert_eq "64 cols / 2 statuses stays a board" "board" "$TD_L_MODE"
assert_eq "  and fills the width" "64" "$(( ${TD_L_COLW[1]} + ${TD_L_COLW[2]} + 1 ))"

assert_eq "below the floor the TUI refuses" "1" "$(_td_layout_compute 19 25 3 1; echo $?)"
assert_eq "short terminal refuses too"      "1" "$(_td_layout_compute 80 7 3 1; echo $?)"
_td_layout_compute 19 25 3 1
assert_contains "refusal explains the requirement" "need 20x8" "$TD_L_ERR"

printf "\n--- chrome sheds in order as height shrinks ---\n"
_td_layout_compute 80 25 3 1; assert_eq "h=25 keeps the peek line" "1" "$TD_L_PEEK"
_td_layout_compute 80 20 3 1; assert_eq "h=20 drops the peek line" "0" "$TD_L_PEEK"
_td_layout_compute 80 12 3 1; assert_eq "h=12 drops the context bar" "0" "$TD_L_CONTEXT"
_td_layout_compute 80 9  3 1; assert_eq "h=9 drops the closing rule" "0" "$TD_L_CLOSE"
_td_layout_compute 96 30 3 1; assert_eq "96x30 earns the three-line peek" "3" "$TD_L_PEEK"

printf "\n--- cell text width reserves the trailing pad ---\n"
_td_layout_textw 26 1; assert_eq "interactive cell: gutter+prio+pads" "21" "$REPLY"
_td_layout_textw 26 0; assert_eq "static cell: no gutter"             "22" "$REPLY"

printf "\n--- scroll window keeps context around the cursor ---\n"
_td_layout_scroll 1  50 19; assert_eq "cursor at top"        "1"  "$REPLY"
_td_layout_scroll 25 50 19; assert_eq "cursor mid-list"      "23" "$REPLY"
_td_layout_scroll 50 50 19; assert_eq "cursor at bottom"     "32" "$REPLY"
_td_layout_scroll 3  10 19; assert_eq "list shorter than the window" "1" "$REPLY"

# ===========================================================================
printf "\n--- frame composition (pure, no terminal) ---\n"
# ===========================================================================
US=$'\x1f'
_TD_UI_STATUSES=(todo doing done)
_TD_UI_LIST=dev
_TD_UI_CUR_COL=2
_TD_UI_MSG=''
_TD_UI_PROMPT=''
typeset -gA _TD_UI_COL=() _TD_UI_COUNT=() _TD_UI_CUR_ROW=() _TD_UI_TOP=() _TD_UI_MARKS=()

mk() { print -r -- "${1}${US}${2}${US}${3}${US}${4}${US}${5}${US}${6}" }
_TD_UI_COL[1,1]="$(mk 4c1a high  api  'Fix auth token refresh' '' 6h)"
_TD_UI_COL[1,2]="$(mk 9b02 medium docs 'Write migration notes' '' 4h)"
_TD_UI_COL[1,3]="$(mk 77a4 low    ui   'Sidebar list counts' '' 2d)"
_TD_UI_COL[2,1]="$(mk 2a3f high   'api db' 'Refactor storage layer' 'https://x.dev/p/42' 3h)"
_TD_UI_COL[3,1]="$(mk aa71 low    core 'Storage lock design' '' 1d)"
_TD_UI_COL[3,2]="$(mk c604 medium core '日本語のタスク 🚀 ação' '' 1d)"
_TD_UI_COUNT=(1 3 2 1 3 2)
_TD_UI_COUNT[1]=3; _TD_UI_COUNT[2]=1; _TD_UI_COUNT[3]=2
_TD_UI_CUR_ROW[1]=1; _TD_UI_CUR_ROW[2]=1; _TD_UI_CUR_ROW[3]=1
_TD_UI_TOP[1]=1; _TD_UI_TOP[2]=1; _TD_UI_TOP[3]=1
_TD_UI_DONE_COUNT=2

_td_layout_compute 80 25 3 1
_td_tui_compose
frame="$REPLY"

# Split the frame back into the lines it addresses, and measure each.
bad=""; nlines=${#reply[@]}
for line in "${reply[@]}"; do
  _td_width "$line"
  (( REPLY == 80 )) || bad+="${REPLY} "
done
assert_eq "frame has one line per screen row" "25" "$nlines"
assert_eq "every composed line is exactly 80 columns" "" "$bad"

printf "\n--- the frame carries the right content ---\n"
plain="$(_td_strip "$frame"; print -r -- "$REPLY")"
assert_contains "list name in the context bar" "dev"    "$plain"
assert_contains "column headers"               "TODO"   "$plain"
assert_contains "task titles (truncated to the cell)" "Fix auth token" "$plain"
assert_contains "CJK and emoji survive"        "日本語のタスク" "$plain"
assert_contains "peek line shows the selected id" "2a3f" "$plain"
assert_contains "command line shows the quit key" "quit" "$plain"

printf "\n--- selection is a tint plus a gutter, never reverse video ---\n"
# Reverse video destroys per-field colour on the one row you are looking at,
# and it is one bit, so cursor and marked would be indistinguishable.
assert_eq "no reverse-video escape anywhere in the frame" "1" \
  "$([[ "$frame" == *$'\033[7m'* ]]; echo $?)"
assert_contains "cursor gutter glyph present" "${TD_GLYPH[cursor]}" "$frame"

_TD_UI_MARKS[2a3f]=1
_td_tui_compose
assert_contains "marked task shows the both-states glyph" "${TD_GLYPH[cursor-marked]}" "$REPLY"
_TD_UI_MARKS=()

printf "\n--- wide characters do not break the grid ---\n"
_TD_UI_COL[1,1]="$(mk 4c1a high api '日本語 🚀 タスク テスト 長い' '' 6h)"
_td_tui_compose
bad=""
for line in "${reply[@]}"; do
  _td_width "$line"
  (( REPLY == 80 )) || bad+="${REPLY} "
done
assert_eq "still exactly 80 columns per line" "" "$bad"

printf "\n--- overflow marker when a column is clipped ---\n"
for i in {1..40}; do _TD_UI_COL[1,$i]="$(mk id$i medium '' "Task number $i" '' 1h)"; done
_TD_UI_COUNT[1]=40
_td_layout_compute 80 25 3 1
_td_tui_compose
assert_contains "clipped column reports the remainder" "more" \
  "$(_td_strip "$REPLY"; print -r -- "$REPLY")"

printf "\n--- narrow terminal degrades instead of breaking ---\n"
_td_layout_compute 60 25 3 1
if [[ "$TD_L_MODE" == board ]]; then
  _td_tui_compose
  bad=""
  for line in "${reply[@]}"; do
    _td_width "$line"
    (( REPLY == 60 )) || bad+="${REPLY} "
  done
  assert_eq "60-column frame is exactly 60 wide" "" "$bad"
else
  assert_eq "60 columns falls back to list mode" "list" "$TD_L_MODE"
fi

test_summary
