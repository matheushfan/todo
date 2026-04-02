---
phase: 03-core-task-crud
plan: 02
subsystem: cli
tags: [zsh, jxa, uuid, crud, autoload, edit, rm]

requires:
  - phase: 03-core-task-crud plan 01
    provides: "_td_resolve_task_id prefix-match helper, td-add/td-ls command patterns"
provides:
  - "td-edit command for task title editing by prefix ID"
  - "td-rm command for task removal by prefix ID"
  - "Complete CRUD surface (add, ls, edit, rm)"
  - "Updated help text listing all commands"
affects: [04-multi-list (CRUD commands need list context), 07-colors (edit/rm output formatting)]

tech-stack:
  added: []
  patterns: ["export env vars before _td_storage_modify for JXA access", "unset env vars after _td_storage_modify to avoid leaking"]

key-files:
  created: [commands/td-edit, commands/td-rm]
  modified: [lib/_td_help, tests/test_crud.zsh]

key-decisions:
  - "Export TASK_ID/NEW_TEXT before _td_storage_modify call, unset after -- simplest env var forwarding approach"
  - "No confirmation prompt on rm -- CLI tool for fast workflows, keep it simple"

patterns-established:
  - "Edit pattern: resolve ID -> export env vars -> _td_storage_modify with findIndex + assignment -> unset vars"
  - "Remove pattern: resolve ID -> export TASK_ID -> _td_storage_modify with filter exclusion -> unset"

requirements-completed: [TASK-02, TASK-03]

duration: 2min
completed: 2026-04-02
---

# Phase 03 Plan 02: Edit & Remove Commands Summary

**td-edit and td-rm commands completing full CRUD surface, with env-var-safe JXA transforms and updated help text listing all 6 commands**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-02T21:49:07Z
- **Completed:** 2026-04-02T21:50:51Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `todo edit <prefix> <new title>` updates task title via JXA findIndex + assignment transform
- `todo rm <prefix>` removes task via JXA filter exclusion transform
- Both commands properly export/unset env vars for safe _td_storage_modify JXA access
- Help text now lists all 6 commands (add, ls, edit, rm, help, version)
- 25 integration tests in test_crud.zsh (7 new for edit/rm), full suite 70 tests green

## Task Commits

Each task was committed atomically:

1. **Task 1: td-edit and td-rm commands (TDD)** - `5e14cc7` (test: RED) + `9949ecf` (feat: GREEN)
2. **Task 2: Help text update** - `083167f` (feat)

## Files Created/Modified
- `commands/td-edit` - Task title editing by prefix ID with exported env vars
- `commands/td-rm` - Task removal by prefix ID with filter-based JXA transform
- `lib/_td_help` - Updated help text with all CRUD commands
- `tests/test_crud.zsh` - 7 new tests for edit/rm (happy path + error cases)

## Decisions Made
- Export TASK_ID/NEW_TEXT before _td_storage_modify, unset after -- simplest approach for env var forwarding to JXA child process
- No confirmation prompt on rm -- keeps CLI fast for power users

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None - all functionality is fully wired.

## Next Phase Readiness
- Full CRUD surface complete (add, ls, edit, rm)
- Ready for Phase 04 (multi-list support) or any phase building on task operations
- All patterns established for future command development

## Self-Check: PASSED

---
*Phase: 03-core-task-crud*
*Completed: 2026-04-02*
