---
phase: 03-core-task-crud
plan: 01
subsystem: cli
tags: [zsh, jxa, uuid, crud, autoload]

requires:
  - phase: 02-storage-engine
    provides: "_td_storage module with add_task, read, modify, list_path"
provides:
  - "td-add command for task creation"
  - "td-ls command for formatted task listing"
  - "_td_resolve_task_id prefix-match helper in _td_core"
affects: [03-core-task-crud plan 02 (edit/rm depend on resolve helper), 07-colors (ls output formatting)]

tech-stack:
  added: []
  patterns: ["JXA formatting inside osascript for list output", "tab-separated JXA output parsed by zsh IFS read loop", "case-insensitive UUID prefix matching via env var"]

key-files:
  created: [commands/td-add, commands/td-ls, tests/test_crud.zsh]
  modified: [lib/_td_core]

key-decisions:
  - "Format td-ls output inside JXA to avoid JSON parsing in zsh (Pitfall 5)"
  - "Use __EMPTY__ sentinel for empty list detection instead of JSON length check in zsh"

patterns-established:
  - "Command pattern: validate input -> _td_storage_init -> get tasks_file -> call storage -> print result"
  - "ID resolution: uppercase prefix + JXA filter + ERROR:not_found/ERROR:ambiguous protocol"

requirements-completed: [TASK-01, TASK-04]

duration: 2min
completed: 2026-04-02
---

# Phase 03 Plan 01: Add & List Commands Summary

**td-add and td-ls commands with UUID prefix-match resolution via JXA, columnar list output, and 15 integration tests**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-02T21:44:39Z
- **Completed:** 2026-04-02T21:47:05Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- `todo add <title>` creates tasks with UUID, prints short 8-char ID confirmation
- `todo ls` displays formatted columnar output (ID, Status, Priority, Title) with header
- `todo ls` on empty list shows friendly "No tasks yet" message
- `_td_resolve_task_id` resolves prefix matches with exact/not-found/ambiguous handling
- 15 integration tests covering all CRUD add/list behavior, full suite (60 tests) green

## Task Commits

Each task was committed atomically:

1. **Task 1: _td_resolve_task_id + td-add** - `29a56a0` (test: RED) + `99446ed` (feat: GREEN)
2. **Task 2: td-ls command** - `0719e0d` (feat: GREEN, tests already in RED commit)
3. **Task 3: Integration tests** - Covered by `29a56a0` (tests created in TDD RED phase)

## Files Created/Modified
- `lib/_td_core` - Added `_td_resolve_task_id` function for UUID prefix matching
- `commands/td-add` - Task creation command with input validation
- `commands/td-ls` - Task listing with JXA-formatted columnar output
- `tests/test_crud.zsh` - 15 integration tests for add, ls, and resolve

## Decisions Made
- Format list output inside JXA (return tab-separated lines) to avoid JSON parsing in zsh
- Use `__EMPTY__` sentinel value from JXA for empty list detection
- Uppercase prefix normalization (`${2:u}`) for case-insensitive UUID matching

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - all functionality is fully wired.

## Next Phase Readiness
- `_td_resolve_task_id` ready for td-edit and td-rm (Plan 03-02)
- Command file pattern established for td-edit and td-rm to follow
- `export TASK_ID` pattern documented for `_td_storage_modify` env var forwarding (needed by edit/rm)

## Self-Check: PASSED

All 5 created/modified files verified on disk. All 3 commit hashes found in git log.

---
*Phase: 03-core-task-crud*
*Completed: 2026-04-02*
