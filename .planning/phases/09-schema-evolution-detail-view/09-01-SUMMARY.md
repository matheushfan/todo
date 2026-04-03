---
phase: 09-schema-evolution-detail-view
plan: 01
subsystem: cli
tags: [zsh, jxa, osascript, json-schema, detail-view]

# Dependency graph
requires:
  - phase: 08-kanban-view-bulk-operations
    provides: "Kanban board rendering, bulk operations, td-ls output"
provides:
  - "td-show detail view command"
  - "td-ref URL attachment command"
  - "ref field in task schema"
  - "ref indicator in td-ls and td-board views"
affects: [future phases needing task metadata, interactive features]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "__EMPTY__ sentinel for JXA tab-separated output with empty fields"
    - "Inline JXA for relative timestamp calculation"

key-files:
  created:
    - commands/td-show
    - commands/td-ref
  modified:
    - lib/_td_storage
    - commands/td-add
    - commands/td-ls
    - lib/_td_board
    - lib/_td_help

key-decisions:
  - "Use __EMPTY__ sentinel in td-show JXA output to prevent zsh IFS read from collapsing empty tab-separated fields"
  - "Ref indicator uses Unicode arrow character (U+2192) appended to task text in list and board views"
  - "Schema evolution is purely additive -- existing tasks without ref field handled via (t.ref || '') in JXA"

patterns-established:
  - "Sentinel pattern: use __EMPTY__ placeholder in JXA output when empty fields must survive zsh read -r parsing"
  - "Inline nested function: _td_show_relative_time defined inside td-show for scoped helper"

requirements-completed: [DATA-01, DATA-02]

# Metrics
duration: 4min
completed: 2026-04-03
---

# Phase 9 Plan 1: Schema Evolution & Detail View Summary

**Added ref field to task schema with td-show card-style detail view and td-ref URL attachment, plus ref indicator in list and board views**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-03T20:06:55Z
- **Completed:** 2026-04-03T20:11:16Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Task schema extended with `ref` field (empty string default, backward compatible)
- `td show <id>` displays full card with ID, Text, Status, Priority, Tags, Ref, Created, Updated
- `td ref <id> [url]` attaches or views reference URLs on tasks
- `td-add` accepts optional `--ref/-r` flag for setting ref at creation
- Ref indicator (arrow) visible in td-ls and td-board for tasks with ref set

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ref to storage, create td-show and td-ref commands** - `141a357` (feat)
2. **Task 2: Integrate ref indicator in td-ls, td-board, update help and dispatch** - `d470ca5` (feat)

## Files Created/Modified
- `commands/td-show` - Card-style detail view displaying all 8 task fields with colors and relative timestamps
- `commands/td-ref` - View or set reference URL on a task via _td_storage_modify
- `lib/_td_storage` - Added TASK_REF env var handling and ref field to _td_storage_add_task
- `commands/td-add` - Added --ref/-r flag and TASK_REF export
- `commands/td-ls` - Added Unicode arrow ref indicator to JXA output
- `lib/_td_board` - Added Unicode arrow ref indicator in kanban and stacked views
- `lib/_td_help` - Added show and ref commands to help text

## Decisions Made
- Used __EMPTY__ sentinel in td-show JXA output to prevent zsh `read` from collapsing consecutive empty tab fields
- Ref indicator uses Unicode arrow (U+2192) appended to task text, keeping rendering logic unchanged
- Schema evolution is purely additive: no migrations, `(t.ref || "")` handles old tasks gracefully
- Relative time helper is an inline nested function in td-show (not in a shared lib) since only show needs it

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing env variable declaration in td-ref JXA transform**
- **Found during:** Task 1
- **Issue:** td-ref _td_storage_modify transform referenced `env` without declaring it. The _td_storage_modify template does not provide an `env` variable.
- **Fix:** Added `var env = $.NSProcessInfo.processInfo.environment;` as first line of transform, matching established pattern in td-edit, td-done, etc.
- **Files modified:** commands/td-ref
- **Verification:** td-ref set and view both work correctly
- **Committed in:** 141a357

**2. [Rule 1 - Bug] Empty fields collapsed by zsh read in td-show**
- **Found during:** Task 1
- **Issue:** When tags and ref are empty, consecutive tab separators in JXA output caused zsh `IFS=$'\t' read` to collapse fields, putting timestamps in wrong variables.
- **Fix:** Used __EMPTY__ sentinel for empty fields in JXA, then replaced with empty string in zsh after read.
- **Files modified:** commands/td-show
- **Verification:** td-show correctly displays all fields including empty tags and ref as em-dash
- **Committed in:** 141a357

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Detail view and ref attachment complete
- Schema is extensible for future fields via same additive pattern
- All existing views updated with ref indicator

---
*Phase: 09-schema-evolution-detail-view*
*Completed: 2026-04-03*

## Self-Check: PASSED
