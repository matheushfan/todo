---
phase: 11-summary-command
plan: 01
subsystem: commands
tags: [summary, cli, prompt-integration]
dependency_graph:
  requires: [_td_storage, _td_color, _td_core]
  provides: [td-summary]
  affects: [_td_help]
tech_stack:
  added: []
  patterns: [zparseopts-flag-parsing, jxa-aggregation, autoload-command]
key_files:
  created:
    - commands/td-summary
  modified:
    - lib/_td_help
decisions:
  - "Insert summary in help between tag and list sections (plan referenced non-existent archive lines)"
metrics:
  duration: 1min
  completed: "2026-04-03T20:43:28Z"
---

# Phase 11 Plan 01: Summary Command

`td summary` with status count aggregation via JXA and `--oneline` for shell prompt embedding.

## What Was Built

- **commands/td-summary**: Autoloaded command that reads active list tasks.json, groups tasks by status using JXA (preserving custom status order from `data.statuses`), and displays counts. Default mode shows colored output with bold list name, cyan status names, and dim total. `--oneline` mode outputs compact `status:count` pairs with no color for prompt integration.
- **lib/_td_help**: Added `summary` and `summary --oneline` entries.

## Task Execution

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create td-summary command | f7098cc | commands/td-summary |
| 2 | Update help text | b0e5f5c | lib/_td_help |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Help text insertion point doesn't exist**
- **Found during:** Task 2
- **Issue:** Plan specified "Insert after the `archive undo` line" but no archive entries exist in _td_help
- **Fix:** Inserted summary entries between tag and list sections (logical grouping)
- **Files modified:** lib/_td_help
- **Commit:** b0e5f5c

## Verification Results

1. `./bin/todo summary` -- shows status counts with colored output
2. `./bin/todo summary --oneline` -- outputs compact single line (e.g., `todo:1`)
3. `./bin/todo help` -- includes summary entries
4. Empty list -- shows "No tasks in list" (not error)

All 4 verification checks passed.

## Known Stubs

None -- all functionality is fully wired.

## Self-Check: PASSED
