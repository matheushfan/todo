#!/usr/bin/env zsh
# Tests for lib/_td_ui: measurement, capability detection, theme, glyphs.
# These are the primitives every view depends on, so alignment bugs anywhere
# else in the tool should surface here first.

source "${0:A:h}/test_helpers.zsh"

TD_ROOT="${0:A:h}/.."
fpath=("$TD_ROOT/lib" "$TD_ROOT/commands" $fpath)
autoload -Uz _td_ui && _td_ui

TD_COLOR_DEPTH=24 TD_ASCII= LANG=pt_BR.UTF-8 _td_ui_init always

# --- display width ----------------------------------------------------------
printf "\n--- width measurement ---\n"
w() { _td_width "$1"; print -r -- "$REPLY" }

assert_eq "ascii"                 "5"  "$(w 'hello')"
assert_eq "portuguese accents"    "4"  "$(w 'ação')"
assert_eq "CJK counts two columns" "12" "$(w '日本語タスク')"
assert_eq "emoji counts two"      "9"  "$(w '🚀 deploy')"
assert_eq "combining mark counts zero" "6" "$(w $'éclair')"
assert_eq "empty string"          "0"  "$(w '')"

printf "\n--- width ignores escape sequences ---\n"
esc_red=$'\033[31m'; esc_off=$'\033[0m'
assert_eq "SGR color ignored"     "4"  "$(w "${esc_red}high${esc_off}")"
assert_eq "cursor sequence ignored" "3" "$(w $'\033[2Kabc')"
osc8=$'\033]8;;https://linear.app/x\033\\LIN-42\033]8;;\033\\'
assert_eq "OSC-8 hyperlink measures its label only" "6" "$(w "$osc8")"

# --- every glyph must be exactly one column ---------------------------------
# A two-column glyph would silently shift every card in the board.
printf "\n--- glyphs occupy exactly one column ---\n"
bad=""
for k in ${(k)TD_GLYPH}; do
  [[ "$k" == (ellipsis|more) ]] && continue   # may legitimately be multi-char in ASCII mode
  _td_width "${TD_GLYPH[$k]}"
  (( REPLY == 1 )) || bad+="$k=${REPLY} "
done
assert_eq "unicode glyph set is single-column" "" "$bad"

TD_ASCII=1 _td_ui_init always
bad=""
for k in ${(k)TD_GLYPH}; do
  [[ "$k" == (ellipsis|more) ]] && continue
  _td_width "${TD_GLYPH[$k]}"
  (( REPLY == 1 )) || bad+="$k=${REPLY} "
done
assert_eq "ascii fallback set is single-column" "" "$bad"
assert_eq "ascii priority keeps v0.2 glyphs" "! ~ ." \
  "${TD_GLYPH[high]} ${TD_GLYPH[medium]} ${TD_GLYPH[low]}"
unset TD_ASCII
LANG=pt_BR.UTF-8 _td_ui_init always

# --- fit produces an exact cell --------------------------------------------
printf "\n--- fit produces exactly the requested width ---\n"
for s in 'deploy' 'ação corrigida e longa demais' '日本語タスク' '🚀 ship' "${esc_red}colored${esc_off}" "$osc8" ''; do
  _td_fit "$s" 12; _td_width "$REPLY"
  assert_eq "fit to 12 cols: ${${s:0:14}//$'\033'/^}" "12" "$REPLY"
done

printf "\n--- truncation and padding ---\n"
t() { _td_trunc "$@"; print -r -- "$REPLY" }
assert_eq "short string untouched" "hello" "$(t 'hello' 10)"
assert_eq "truncates with ellipsis" "hel…"  "$(t 'hello world' 4)"
assert_eq "never exceeds budget on CJK" "0" \
  "$(_td_trunc '日本語タスク' 5; _td_width "$REPLY"; (( REPLY <= 5 )); echo $?)"
p() { _td_pad "$@"; print -r -- "$REPLY" }
assert_eq "pad left"   "ab   " "$(p 'ab' 5)"
assert_eq "pad right"  "   ab" "$(p 'ab' 5 r)"
assert_eq "pad center" " ab  " "$(p 'ab' 5 c)"

# --- capability detection ---------------------------------------------------
printf "\n--- colour capability precedence ---\n"
d() { ( unset NO_COLOR CLICOLOR_FORCE TD_COLOR_DEPTH COLORTERM TERM_PROGRAM TERM
        local want=auto
        while (( $# )); do [[ "$1" == want=* ]] && want="${1#want=}" || export "$1"; shift; done
        _td_ui_detect "$want"; print -r -- $TD_DEPTH ) }

assert_eq "NO_COLOR beats truecolor"  "0"  "$(d NO_COLOR=1 COLORTERM=truecolor TERM=xterm-256color)"
assert_eq "--color=never wins"        "0"  "$(d want=never COLORTERM=truecolor TERM=xterm-256color)"
assert_eq "--color=always beats pipe" "24" "$(d want=always COLORTERM=truecolor TERM=xterm-256color)"
assert_eq "TERM=dumb outranks always" "0"  "$(d want=always TERM=dumb)"
assert_eq "iTerm2 gets truecolor"     "24" "$(d want=always TERM_PROGRAM=iTerm.app TERM=xterm-256color)"
# Apple's Terminal.app is 256-colour only; sending 24-bit there yields wrong
# colours rather than a graceful fallback.
assert_eq "Apple Terminal capped at 256" "8" \
  "$(d want=always TERM_PROGRAM=Apple_Terminal COLORTERM=truecolor TERM=xterm-256color)"
assert_eq "plain 256color TERM"       "8"  "$(d want=always TERM=xterm-256color)"

printf "\n--- unicode detection ---\n"
u() { ( unset TD_ASCII LC_ALL LC_CTYPE LANG
        while (( $# )); do export "$1"; shift; done
        _td_ui_detect always; print -r -- $TD_UNICODE ) }
assert_eq "UTF-8 locale enables glyphs" "1" "$(u LANG=pt_BR.UTF-8)"
assert_eq "C locale falls back to ASCII" "0" "$(u LANG=C)"
assert_eq "TD_ASCII forces fallback"     "0" "$(u LANG=pt_BR.UTF-8 TD_ASCII=1)"

# --- theme ------------------------------------------------------------------
printf "\n--- theme tokens ---\n"
TD_COLOR_DEPTH=24 _td_ui_init always
assert_contains "24-bit emits an RGB sequence" "38;2;" "${TD_T[fg-accent]}"
TD_COLOR_DEPTH=8 _td_ui_init always
assert_contains "256 emits an indexed sequence" "38;5;" "${TD_T[fg-accent]}"
TD_COLOR_DEPTH=4 _td_ui_init always
assert_eq "16-colour surface declines to paint a background" "" "${TD_T[bg-surface]}"
TD_COLOR_DEPTH=0 _td_ui_init always
assert_eq "no-colour mode emits nothing" "" "${TD_T[fg-accent]}"
_td_paint accent "text"
assert_eq "paint is a no-op without colour" "text" "$REPLY"

printf "\n--- hyperlinks ---\n"
TD_COLOR_DEPTH=24 _td_ui_init always
_td_link "https://example.com" "LIN-42"
assert_contains "link wraps the label in OSC-8" "example.com" "$REPLY"
_td_width "$REPLY"
assert_eq "link measures as its label" "6" "$REPLY"
TD_COLOR_DEPTH=0 _td_ui_init always
_td_link "https://example.com" "LIN-42"
assert_eq "link degrades to plain text" "LIN-42" "$REPLY"

test_summary
