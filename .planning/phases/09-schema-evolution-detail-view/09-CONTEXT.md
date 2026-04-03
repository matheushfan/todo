# Phase 9: Schema Evolution & Detail View - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Add `ref` field to task schema and create `td show` (detail view) and `td ref` (attach URL) commands. Schema evolution is additive — no migrations, existing tasks without ref field continue to work.

</domain>

<decisions>
## Implementation Decisions

### Detail View Format
- Card-style layout with aligned labels: ID, Status, Priority, Tags, Ref, Created, Updated, Text
- Timestamps displayed as relative ("2 hours ago") with absolute in parentheses
- Colors: priority colorized, labels in dim, values in normal — consistent with td-ls

### Ref Field Design
- Single URL string per task (field name: `ref`), not an array
- In td-ls/board: subtle indicator `→` or `[ref]` next to title when ref exists, no full URL shown
- `td ref <id>` without second arg shows the current ref; `td ref <id> <url>` sets it

### Claude's Discretion
- Exact formatting of relative timestamps (e.g., rounding to "2h ago" vs "2 hours ago")
- Whether td show uses box-drawing characters or plain formatting
- Internal implementation of ref display indicator in td-ls output

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `_td_storage_modify()` — JXA transform pattern for updating task fields
- `_td_storage_read()` — JXA query pattern for reading task data
- `_td_resolve_task_id()` — UUID prefix matching (8-char prefix)
- `_td_color` — Color constants, `_td_printf_colored()`, `_td_visible_len()`
- `_td_help` — Help text heredoc to update

### Established Patterns
- Env var passing for JXA (TASK_ID, NEW_TEXT, etc) — safe from injection
- Export before _td_storage_modify, unset after
- zparseopts -D -E for optional flag parsing
- Tab-separated JXA output for structured data
- Autoload -Uz for lazy function loading

### Integration Points
- `bin/todo` — add td-show and td-ref to dispatch and autoload
- `lib/_td_storage` — add_task must include ref field (default empty string)
- `commands/td-add` — optional --ref flag
- `commands/td-ls` — ref indicator in output
- `lib/_td_board` — ref indicator on cards
- `lib/_td_help` — add show and ref to help text

</code_context>

<specifics>
## Specific Ideas

- Ref field defaults to empty string "" for new tasks, undefined/missing for existing tasks
- JXA handles both cases: `task.ref || ""` for display
- td show outputs a full card with all fields, one per line, with label: value format

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>
