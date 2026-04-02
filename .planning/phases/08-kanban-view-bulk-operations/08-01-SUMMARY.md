---
phase: 08-kanban-view-bulk-operations
plan: 01
subsystem: ui
tags: [kanban, terminal-rendering, ansi, columns, board]

requires:
  - phase: 07-colored-output
    provides: ANSI color primitives (_td_strip_ansi, _td_visible_len, _td_printf_colored)
provides:
  - Kanban board rendering engine (lib/_td_board)
  - td-board command entry point
  - Side-by-side column layout with auto-sizing
  - Stacked vertical fallback for narrow terminals
  - Default command changed from help to board
affects: [08-02-bulk-operations, future-ui-phases]

tech-stack:
  added: []
  patterns: [row-by-row column rendering, JXA-side task grouping, __COL_SEP__ delimiter]

key-files:
  created: [lib/_td_board, commands/td-board, tests/test_board.zsh]
  modified: [bin/todo, lib/_td_help, tests/test_dispatch.zsh]

key-decisions:
  - "Declare all locals before loops to avoid zsh local-in-loop output leak"
  - "Single JXA call groups all tasks by status using __COL_SEP__ delimiter"
  - "Truncate plain text before colorizing to avoid splitting ANSI escape sequences"

patterns-established:
  - "Row-by-row column rendering: iterate max_rows, print one cell per column per line"
  - "JXA grouping: single osascript call returns blocks separated by __COL_SEP__"
  - "Width fallback: col_width < 20 triggers stacked vertical layout"

requirements-completed: [VIEW-02, VIEW-03]

duration: 4min
completed: 2026-04-02
---

# Phase 8 Plan 1: Kanban Board View Summary

**Side-by-side kanban board with auto-sizing columns per status, stacked fallback for narrow terminals, and default command changed to board**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-02T23:44:10Z
- **Completed:** 2026-04-02T23:48:14Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Kanban board renders tasks in side-by-side columns (one per status) with auto-calculated widths
- Priority indicators (! alta, ~ media, . baixa), short IDs, and truncated text fit within column width
- Stacked vertical fallback triggers automatically when terminal too narrow (col_width < 20)
- Default command changed from `help` to `board` -- kanban is now the first thing users see
- 23 new board tests covering headers, tasks, separators, priority, truncation, stacked fallback, empty columns, empty board

## Task Commits

Each task was committed atomically:

1. **Task 1: Create _td_board rendering library and test suite (TDD)**
   - `535da03` (test) - Failing board tests (RED)
   - `3238583` (feat) - Kanban rendering engine implementation (GREEN)
2. **Task 2: Create td-board command, wire default dispatch, update help** - `a61b262` (feat)

## Files Created/Modified

- `lib/_td_board` - Kanban rendering engine: _td_board_render, _td_board_format_card, _td_board_stacked
- `commands/td-board` - Board command entry point, calls _td_board_render
- `tests/test_board.zsh` - 23 tests for board rendering (side-by-side, stacked, truncation, empty)
- `bin/todo` - Added _td_board autoload, changed default command to board
- `lib/_td_help` - Added board and bulk commands to help text
- `tests/test_dispatch.zsh` - Updated for new default command (board instead of help)

## Decisions Made

- **Declare all locals before loops:** zsh re-declares `local` inside loops and outputs previous values to stdout. Moved all local declarations before the for-loop body to prevent output leaks.
- **Single JXA grouping call:** One osascript call groups all tasks by status using `__COL_SEP__` delimiter, avoiding O(n) process forks per status column.
- **Truncate before colorize:** Plain text is truncated first, then colors applied, preventing ANSI escape code corruption.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed zsh local-in-loop output leak**
- **Found during:** Task 2 (wiring td-board command, testing with TTY)
- **Issue:** `local var=value` inside a for-loop in zsh outputs the previous variable value when re-declaring, causing debug-like output mixed into board rendering
- **Fix:** Moved all `local` declarations to before the loop, used plain assignment inside loops
- **Files modified:** lib/_td_board
- **Verification:** Board output clean with multiple tasks, all 23 tests pass
- **Committed in:** a61b262 (part of Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Bug fix necessary for correct rendering. No scope creep.

## Issues Encountered

None beyond the auto-fixed deviation above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Kanban board rendering complete, provides visual foundation for all future features
- Board command wired and set as default
- Help text pre-populated with `bulk` command entry for 08-02 plan

## Self-Check: PASSED

- All 3 created files exist (lib/_td_board, commands/td-board, tests/test_board.zsh)
- All 3 commits verified (535da03, 3238583, a61b262)
- All 23 board tests pass

---
*Phase: 08-kanban-view-bulk-operations*
*Completed: 2026-04-02*
