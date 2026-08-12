---
gsd_state_version: 1.0
milestone: v0.3
milestone_name: Correctness & Visual Overhaul
status: in-progress
stopped_at: Completed phase 18 (ls + summary redesign)
last_updated: "2026-08-11"
last_activity: 2026-08-11
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 5
  completed_plans: 4
  percent: 80
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Gerenciar tasks direto no terminal de forma rapida e visual, sem sair do fluxo de trabalho.
**Current focus:** Phase 19 — interactive TUI rebuilt on the raw-ANSI core

## Current Position

Phase: 19 (not started)
Status: phases 15-18 complete and committed; TUI still runs on the old zcurses engine
Last activity: 2026-08-11

Progress: [████████░░] 80%

## What Shipped in v0.3 So Far

- **Storage locking** (`lib/_td_lock`). Concurrent writes used to lose 94-95% of
  tasks silently, because the temp+mv write kept the file valid JSON so nothing
  ever surfaced the loss. Measured 20 parallel adds: 1 survivor before, 20 after.
- **Four user-facing bug fixes**: `ls` rendering the title under the Tags column
  for every untagged task; `done` meaning "last status" rather than "done";
  `add -t a,b` (the README's own example) being rejected; `show` scrambling
  fields when the text held a TAB.
- **`lib/_td_ui`**, one measurement/theme/glyph core shared by every view.
- **Redesigned static board, `ls` and `summary`**, laid out to exactly 80
  columns, aligned through CJK/emoji/accents.

## Accumulated Context

### Decisions

- [Phase 15]: Lock is a directory (`mkdir`, never `mkdir -p` — the latter never
  fails, so it can never serialise). Owner PID file enables stale detection.
- [Phase 15]: Lock traps live at the TOP LEVEL of bin/todo. Verified on zsh 5.9
  that a trap installed inside a function is function-local and fires on that
  function's return, which would release every lock immediately.
- [Phase 15]: Waiting uses `zselect` (fork-free, ~0.001ms) rather than `sleep`,
  which costs a fork+exec (~1.7ms) per wait.
- [Phase 16]: Field separator is U+001F, not TAB. TAB is IFS whitespace, so zsh
  `read` collapses runs of it and empty fields shift every later column.
- [Phase 16]: "Done" means a status literally named `done` if the list has one,
  else the last status. Shared as one `_tdDoneStatus()` JXA helper so the
  definition cannot drift between done / bulk / archive / the TUI.
- [Phase 17]: Text is measured with zsh's native `${(m)#s}` — CJK 2, combining
  marks 0, emoji 2. No wcwidth table needed.
- [Phase 17]: Rendering helpers return via `REPLY`, not stdout. `$(...)` forks a
  subshell per call: 2.03ms/cell vs 0.043ms.
- [Phase 17]: The interactive UI will be raw ANSI, not zcurses. `zcurses attr`
  only accepts the 8 named colours, which forces a black background and fights
  the user's theme. A raw-ANSI prototype was verified to restore terminal state
  byte-identically on exit.
- [Phase 17]: Board has no outer frame — that is what frees the two columns that
  make 26+1+26+1+26 = 80 land exactly.
- [Phase 18]: `summary --oneline` is frozen byte-for-byte; the README tells
  people to put it in ~/.zshrc.

### Blockers/Concerns

- Phase 19 (TUI rewrite) is the largest remaining piece: `lib/_td_interactive`
  is 1114 lines of zcurses and needs porting onto `_td_ui` + raw ANSI.
- Salvaged reference code for that port: a working raw-ANSI prototype and a key
  decoder (arrows, Home/End, PgUp/PgDn, Shift-Tab, Alt-, Ctrl-, SGR mouse) live
  in the session scratchpad under `ansi-tui/`.
- Audit findings not yet addressed: dangling `active_list` handled
  inconsistently across commands; `bulk done --status <invalid>` succeeds
  silently while `bulk move` errors; `tag add` prints literal `'\''` escapes;
  `archive` discards the return code of its second write.
