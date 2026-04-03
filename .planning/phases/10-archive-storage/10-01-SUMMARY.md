---
phase: 10-archive-storage
plan: 01
subsystem: archive
tags: [archive, storage, commands]
dependency_graph:
  requires: [storage-engine, core-utilities, color-library]
  provides: [td-archive, _td_storage_archive_path]
  affects: [help-text]
tech_stack:
  added: []
  patterns: [append-first-then-remove, subcommand-dispatch, lazy-file-creation]
key_files:
  created: [commands/td-archive]
  modified: [lib/_td_storage, lib/_td_help]
decisions:
  - "Append-first-then-remove ordering for crash-safe cross-file transfers"
  - "Dim color for archive ls output to visually distinguish historical data"
  - "Lazy archive.json creation on first archive call"
  - "Remove archived_at field on undo restore"
metrics:
  duration: 2min
  completed: "2026-04-03T20:35:00Z"
---

# Phase 10 Plan 01: Archive Storage Summary

td-archive command with archive/ls/undo subcommands using separate archive.json per list, crash-safe append-first-then-remove pattern, and lazy file creation.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add _td_storage_archive_path and create td-archive | 3f125e4 | lib/_td_storage, commands/td-archive |
| 2 | Update help text and verify end-to-end | d594ca6 | lib/_td_help |

## Implementation Details

### td-archive (default) - DATA-03
- Reads tasks.json, filters tasks matching last status (done equivalent)
- Appends matched tasks to archive.json with `archived_at` ISO timestamp
- Removes archived tasks from tasks.json
- Creates archive.json lazily on first call with `{name, tasks: []}` schema
- Reports count: "Archived N task(s)"

### td-archive ls - DATA-04
- Reads archive.json, formats as table with ID/Status/Priority/Tags/Title
- Uses dim color for entire output to indicate historical data
- Handles missing archive.json gracefully ("No archived tasks")

### td-archive undo
- Resolves task ID from archive.json via _td_resolve_task_id
- Restores task to active tasks.json (removes archived_at, updates timestamp)
- Uses reverse append-first-then-remove (add to active first, then remove from archive)

### _td_storage_archive_path
- Returns `$TD_DATA/lists/{list}/archive.json` path
- Follows same pattern as _td_storage_list_path

## Decisions Made

1. **Append-first-then-remove for crash safety**: Write to destination file before removing from source. If crash occurs mid-operation, tasks exist in both files (recoverable) rather than neither (data loss).
2. **Dim color for archive ls**: Visually distinguishes archived/historical data from active tasks.
3. **Lazy archive.json**: No empty archive files created at list creation time; created on first `td archive` call.
4. **archived_at removed on undo**: Restored tasks rejoin active list cleanly without archive metadata.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Verification Results

- td archive moves done tasks to archive.json with archived_at timestamp: PASS
- td archive ls displays archived tasks with all fields: PASS
- td archive undo restores task to active list: PASS
- Active operations (ls, board) never show archived tasks: PASS
- Help text lists all archive commands: PASS
- archive.json created lazily: PASS
- Crash-safe ordering (append-first-then-remove): PASS

## Self-Check: PASSED
