# Roadmap: todolist-cli

## Overview

Build a zero-dependency CLI task manager in pure zsh, progressing from storage engine through CRUD operations, multi-list management, and culminating in the kanban visualization that is the project's core differentiator. Each phase delivers a working, testable capability that builds on the previous.

## Milestones

- ✅ **v1.0 MVP** — Phases 1-8 (shipped 2026-04-03) — [Archive](./milestones/v1.0-ROADMAP.md)
- 🚧 **v1.1 Interactive Experience** — Phases 9-14 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-8) — SHIPPED 2026-04-03</summary>

- [x] Phase 1: Project Scaffolding & CLI Dispatch (1/1 plans)
- [x] Phase 2: Storage Engine (1/1 plans)
- [x] Phase 3: Core Task CRUD (2/2 plans)
- [x] Phase 4: Task Workflow (1/1 plans)
- [x] Phase 5: Multi-List Management (1/1 plans)
- [x] Phase 6: Custom Statuses & Tags (2/2 plans)
- [x] Phase 7: Colored Output & List View (1/1 plans)
- [x] Phase 8: Kanban View & Bulk Operations (2/2 plans)

</details>

### v1.1 Interactive Experience

- [ ] **Phase 9: Schema Evolution & Detail View** - Add refs field to tasks and td-show/td-ref commands for viewing and linking task details
- [ ] **Phase 10: Archive Storage** - Move completed tasks to separate archive.json, with td-archive command for archiving and querying
- [ ] **Phase 11: Summary Command** - td-summary with task counts by status and --oneline for prompt integration
- [ ] **Phase 12: Interactive Engine Foundation** - td-ui entry point with zcurses-based terminal lifecycle, render loop, and clean exit on all paths
- [ ] **Phase 13: Interactive Navigation & Actions** - Keyboard navigation (j/k/h/l + arrows), status cycling, done/delete, and open ref URL from interactive view
- [ ] **Phase 14: Checkbox Mode & Polish** - Checkbox rendering for simple lists, help overlay, and graceful terminal resize handling

## Phase Details

### Phase 9: Schema Evolution & Detail View
**Goal**: Users can view full task details and attach reference URLs to any task
**Depends on**: Phase 8 (v1.0 complete)
**Requirements**: DATA-01, DATA-02
**Success Criteria** (what must be TRUE):
  1. User can run `td show <id>` and see all task fields (text, status, priority, tags, refs, created, updated)
  2. User can run `td ref <id> <url>` to attach a URL/reference to any task
  3. Existing tasks without refs field continue to work (backward compatible schema evolution)
**Plans:** 1 plan
Plans:
- [ ] 09-01-PLAN.md — Schema ref field, td-show detail view, td-ref command, ref indicator in ls/board

### Phase 10: Archive Storage
**Goal**: Users can archive completed tasks without deleting them and query the archive later
**Depends on**: Phase 9
**Requirements**: DATA-03, DATA-04, DATA-05
**Success Criteria** (what must be TRUE):
  1. User can run `td archive` to move completed tasks from active list to archive
  2. User can run `td archive ls` and see previously archived tasks with all original fields
  3. Archived tasks are stored in a separate archive.json per list (not mixed with active tasks)
  4. Active task operations (ls, board, bulk) never load or display archived tasks
**Plans**: TBD

### Phase 11: Summary Command
**Goal**: Users can get a quick overview of pending work across lists without opening the board
**Depends on**: Phase 9
**Requirements**: UX-06
**Success Criteria** (what must be TRUE):
  1. User can run `td summary` and see task counts grouped by status for the active list
  2. Output is concise enough for prompt integration or quick glance
**Plans**: TBD

### Phase 12: Interactive Engine Foundation
**Goal**: Users can enter a persistent interactive board view that renders via zcurses and exits cleanly
**Depends on**: Phase 11
**Requirements**: TUI-01, TUI-06, TUI-07
**Success Criteria** (what must be TRUE):
  1. User can run `td ui` and see the kanban board rendered in a zcurses-managed terminal
  2. Interactive view uses the alternate screen buffer (user's scrollback is preserved)
  3. Pressing `q` exits cleanly and restores the terminal to its original state
  4. Terminal state is restored on Ctrl+C, SIGTERM, and any abnormal exit path
  5. The interactive view renders using `zsh/curses` module (zcurses), not raw ANSI + read -k
**Plans**: TBD
**UI hint**: yes

### Phase 13: Interactive Navigation & Actions
**Goal**: Users can navigate tasks and perform actions entirely from keyboard within the interactive view
**Depends on**: Phase 12
**Requirements**: TUI-02, TUI-03, TUI-04, TUI-05
**Success Criteria** (what must be TRUE):
  1. User can move selection between tasks with j/k (up/down) and h/l (left/right between columns), plus arrow keys
  2. User can press `s` on a selected task to cycle its status to the next column
  3. User can press `d` to mark a task done and `x` to delete it from the interactive view
  4. User can press `o` on a task with a ref URL to open it in the default browser
**Plans**: TBD
**UI hint**: yes

### Phase 14: Checkbox Mode & Polish
**Goal**: Users can use a simplified checkbox view for simple lists and the interactive experience handles edge cases gracefully
**Depends on**: Phase 13
**Requirements**: UX-05, UX-07, UX-08
**Success Criteria** (what must be TRUE):
  1. User can view tasks in checkbox mode ([ ]/[x]) for lists that only need todo/done
  2. User can press `?` in interactive mode to see a help overlay listing all keybindings
  3. Resizing the terminal during interactive mode redraws the layout correctly without crashing
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 9 → 10 → 11 → 12 → 13 → 14

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Project Scaffolding & CLI Dispatch | v1.0 | 1/1 | Complete | 2026-04-02 |
| 2. Storage Engine | v1.0 | 1/1 | Complete | 2026-04-02 |
| 3. Core Task CRUD | v1.0 | 2/2 | Complete | 2026-04-02 |
| 4. Task Workflow | v1.0 | 1/1 | Complete | 2026-04-02 |
| 5. Multi-List Management | v1.0 | 1/1 | Complete | 2026-04-02 |
| 6. Custom Statuses & Tags | v1.0 | 2/2 | Complete | 2026-04-02 |
| 7. Colored Output & List View | v1.0 | 1/1 | Complete | 2026-04-02 |
| 8. Kanban View & Bulk Operations | v1.0 | 2/2 | Complete | 2026-04-02 |
| 9. Schema Evolution & Detail View | v1.1 | 0/1 | Planning complete | - |
| 10. Archive Storage | v1.1 | 0/TBD | Not started | - |
| 11. Summary Command | v1.1 | 0/TBD | Not started | - |
| 12. Interactive Engine Foundation | v1.1 | 0/TBD | Not started | - |
| 13. Interactive Navigation & Actions | v1.1 | 0/TBD | Not started | - |
| 14. Checkbox Mode & Polish | v1.1 | 0/TBD | Not started | - |
