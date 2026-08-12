#!/usr/bin/env zsh
# Regression tests: one case per bug that shipped and was fixed.
# Each block names the symptom a user would have seen, so a future failure
# reads as "this bug came back" rather than "some assertion broke".

source "${0:A:h}/test_helpers.zsh"

TEST_DATA=$(mktemp -d)
export TODOLIST_DATA="$TEST_DATA"
trap 'rm -rf "$TEST_DATA"' EXIT

fresh() { rm -rf "$TODOLIST_DATA"; mkdir -p "$TODOLIST_DATA"; }
last_id() { zsh "$TD_BIN" ls | tail -1 | awk '{print $1}'; }
status_of() {  # status_of <id-prefix>
  zsh "$TD_BIN" show "$1" | awk '/^ *Status/ {print $2}'
}

# --- `todo ls` put the title in the Tags column -----------------------------
# TAB is an IFS whitespace character, so zsh `read` collapsed the run of tabs
# produced by an empty tags field and shifted every later column left. It hit
# the most common case: any task without tags.
printf "\n--- ls column alignment ---\n"
fresh
zsh "$TD_BIN" add "Task without tags" >/dev/null
zsh "$TD_BIN" add -t backend "Task with tag" >/dev/null
ls_out=$(zsh "$TD_BIN" ls)

# Compare against the header's own column offsets: the title must begin exactly
# where the "Title" heading begins, whether or not the task has tags.
header=$(print -r -- "$ls_out" | head -1)
title_col=$(( ${#${header%%Title*}} + 1 ))
tags_col=$((  ${#${header%%Tags*}}  + 1 ))

untagged_row=$(print -r -- "$ls_out" | grep 'Task without tags')
assert_eq "untagged task: title starts in the Title column" "Task without tags" \
  "${untagged_row[$title_col,-1]}"
assert_eq "untagged task: Tags column is blank" "" \
  "${${untagged_row[$tags_col,$((title_col - 1))]}// /}"

tagged_row=$(print -r -- "$ls_out" | grep 'Task with tag')
assert_eq "tagged task: tag sits in the Tags column" "backend" \
  "${${tagged_row[$tags_col,$((title_col - 1))]}// /}"
assert_eq "tagged task: title still starts in the Title column" "Task with tag" \
  "${tagged_row[$title_col,-1]}"

# --- `todo done` moved tasks to the LAST status, whatever it was ------------
# It used data.statuses[length-1]. Following the README's own example
# (`todo status add in-review`) made `done` silently mean `in-review`, while
# still printing "Completed task".
printf "\n--- done resolves the real done status ---\n"
fresh
zsh "$TD_BIN" add "Ship it" >/dev/null
zsh "$TD_BIN" status add "in-review" >/dev/null
id=$(last_id)
done_out=$(zsh "$TD_BIN" done "$id")
assert_eq "done -> 'done', not the trailing custom status" "done" "$(status_of "$id")"
assert_contains "done names the status it used" "done" "$done_out"

# --- `bulk done` had the same defect ----------------------------------------
fresh
zsh "$TD_BIN" add "Bulk one" >/dev/null
zsh "$TD_BIN" status add "in-review" >/dev/null
id=$(last_id)
zsh "$TD_BIN" bulk done "$id" >/dev/null
assert_eq "bulk done -> 'done', not the trailing status" "done" "$(status_of "$id")"

# --- `todo archive` archived whatever sat in the last status ----------------
printf "\n--- archive only takes completed tasks ---\n"
fresh
zsh "$TD_BIN" add "Finished" >/dev/null
fin=$(last_id)
zsh "$TD_BIN" status add "in-review" >/dev/null
zsh "$TD_BIN" done "$fin" >/dev/null
zsh "$TD_BIN" add "Still reviewing" >/dev/null
rev=$(last_id)
zsh "$TD_BIN" move "$rev" in-review >/dev/null
zsh "$TD_BIN" archive >/dev/null
remaining=$(zsh "$TD_BIN" ls)
assert_contains "in-review task survives archive" "Still reviewing" "$remaining"
assert_eq "completed task left the active list" "1" \
  "$([[ "$remaining" == *Finished* ]]; echo $?)"

# --- `todo add -t a,b` was rejected, though the README documents it ---------
printf "\n--- comma-separated tags ---\n"
fresh
add_out=$(zsh "$TD_BIN" add -t backend,urgent "Refactor auth" 2>&1)
assert_exit_code "comma-separated tags accepted" "0" "$?"
id=$(last_id)
show_out=$(zsh "$TD_BIN" show "$id")
assert_contains "first comma tag stored" "backend" "$show_out"
assert_contains "second comma tag stored" "urgent" "$show_out"

zsh "$TD_BIN" add -t dup,dup "Dedupe" >/dev/null
tags_line=$(zsh "$TD_BIN" show "$(last_id)" | grep 'Tags')
assert_eq "repeated tag collapses to one" "1" \
  "$(print -r -- "$tags_line" | grep -o 'dup' | wc -l | tr -d ' ')"

# --- `todo show` scrambled every field when the text held a TAB -------------
printf "\n--- show survives a TAB inside the task text ---\n"
fresh
zsh "$TD_BIN" add $'before\tafter' >/dev/null
id=$(last_id)
assert_eq "status not shifted by an embedded TAB" "todo" "$(status_of "$id")"
assert_contains "text preserved intact" "before	after" "$(zsh "$TD_BIN" show "$id")"

# --- concurrent writes silently lost tasks ----------------------------------
# Unlocked read-modify-write: 20 parallel adds used to leave 1 task, with all
# 20 reporting success. The file stayed valid JSON, so nothing warned.
printf "\n--- concurrent adds do not lose data ---\n"
fresh
zsh "$TD_BIN" add "seed" >/dev/null
for i in {1..9}; do zsh "$TD_BIN" add "parallel-$i" >/dev/null 2>&1 & done
wait
count=$(zsh "$TD_BIN" ls | tail -n +2 | grep -c .)
assert_eq "all 10 concurrent writes survive" "10" "$count"

leftovers=$(find "$TODOLIST_DATA" \( -name '*.lock' -o -name '*.tmp.*' -o -name '*.stale.*' \) | wc -l | tr -d ' ')
assert_eq "no lock or temp debris left behind" "0" "$leftovers"

# --- version string had gone stale two releases back ------------------------
printf "\n--- version reporting ---\n"
ver=$(zsh "$TD_BIN" version)
assert_eq "version is semver-shaped" "0" "$([[ "$ver" == todo\ v<->.<->.<-> ]]; echo $?)"

# --- help text documented priorities that no longer exist -------------------
printf "\n--- help text is current ---\n"
help_out=$(zsh "$TD_BIN" help)
assert_eq "no leftover Portuguese priority values" "1" \
  "$([[ "$help_out" == *alta* || "$help_out" == *baixa* ]]; echo $?)"
assert_contains "help documents the real priorities" "high, medium, low" "$help_out"
for cmd in show ref archive summary bulk; do
  assert_contains "help documents '$cmd'" "$cmd" "$help_out"
done

test_summary
