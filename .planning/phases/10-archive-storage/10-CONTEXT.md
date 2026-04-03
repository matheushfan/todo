# Phase 10: Archive Storage - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Move completed tasks to separate archive.json per list. Provide td-archive command for archiving and querying. Active operations never load archived data.

</domain>

<decisions>
## Implementation Decisions

### Archive Behavior
- `td archive` with no args archives all tasks with status = last status (done equivalent)
- `td archive undo <id>` restores a task from archive back to active list
- `td archive ls` uses same format as td-ls — table with ID, Status, Priority, Tags, Title — but without colors (archived = historical)

### Storage Design
- Separate archive.json per list namespace, alongside tasks.json
- Schema: `{name: "list-name", tasks: [...]}` — same task objects, no statuses array
- Active operations (td-ls, td-board, td-bulk) never load archive.json

### Claude's Discretion
- Whether to add `archived_at` timestamp when moving to archive
- Error handling when archive.json doesn't exist yet (create on first archive)
- Whether td archive ls supports --status/--priority filters

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_td_storage_modify()` — JXA transform for moving tasks between files
- `_td_storage_atomic_write()` — safe file write for archive.json
- `_td_storage_read()` — JXA read for archive queries
- `_td_storage_list_path()` — derive archive path from list path
- `_td_resolve_task_id()` — UUID prefix match works on any task array

### Established Patterns
- Env var passing to JXA for task operations
- Subcommand dispatch in single file (td-list, td-tag, td-status pattern)
- Two atomic writes for cross-file operations (append-first to prevent data loss)

### Integration Points
- `bin/todo` — add td-archive to dispatch and autoload
- `lib/_td_help` — add archive commands to help text
- `lib/_td_storage` — may need _td_storage_archive_path() helper

</code_context>

<specifics>
## Specific Ideas

- Archive is append-first-then-remove to prevent data loss on crash
- archive.json created lazily on first td archive call
- td archive ls reads archive.json via same _td_storage_read pattern

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>
