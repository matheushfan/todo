# Requirements: todolist-cli

**Defined:** 2026-04-02
**Core Value:** Gerenciar tasks direto no terminal de forma rápida e visual, sem sair do fluxo de trabalho.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Task Management

- [x] **TASK-01**: User can create a task with title via CLI command
- [x] **TASK-02**: User can edit the title of an existing task
- [x] **TASK-03**: User can remove a task permanently
- [x] **TASK-04**: User can list all tasks in the current list with formatted output
- [x] **TASK-05**: User can mark a task as completed (move to final status)
- [x] **TASK-06**: User can move a task to any status defined in the list
- [x] **TASK-07**: User can perform bulk operations on multiple tasks at once

### Priorities

- [x] **PRIO-01**: User can assign priority (alta/média/baixa) when creating or editing a task
- [x] **PRIO-02**: Tasks display with color-coded priorities (vermelho/amarelo/verde)

### Multi-List

- [x] **LIST-01**: User can create multiple named lists
- [x] **LIST-02**: User can switch between lists with a single command
- [x] **LIST-03**: System uses a default list when none is specified
- [x] **LIST-04**: User can define custom statuses per list (columns do kanban)

### Visualization

- [x] **VIEW-01**: Task listing displays with colored output using ANSI escape codes
- [ ] **VIEW-02**: Kanban inline view renders columns side-by-side per status
- [ ] **VIEW-03**: Automatic fallback to stacked list view when terminal is too narrow

### Tags

- [x] **TAG-01**: User can add one or more tags to a task
- [x] **TAG-02**: User can filter tasks by status and priority

### Storage & Infrastructure

- [x] **STOR-01**: All data stored centrally in ~/.todolist/ with namespaces per list
- [x] **STOR-02**: Data persisted as JSON flat files with atomic write-to-temp + mv pattern
- [x] **STOR-03**: Zero external dependencies — pure zsh with macOS built-in utilities only
- [x] **STOR-04**: JSON read/write handled via osascript JXA (built-in macOS)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Search & Filtering

- **SRCH-01**: User can filter tasks by tag
- **SRCH-02**: User can search tasks by free text across all fields
- **SRCH-03**: User can filter across multiple lists simultaneously

### Polish & UX

- **UX-01**: Zsh tab completions for commands, list names, and tags
- **UX-02**: Built-in help system with usage examples per command
- **UX-03**: NO_COLOR environment variable support
- **UX-04**: Export/import lists to portable format

## Out of Scope

| Feature | Reason |
|---------|--------|
| Due dates / deadlines | Complexidade desnecessária pro v1, foco é simplicidade |
| Sync com serviços externos | Manter offline-first e simples |
| TUI interativa (ncurses) | O valor é nos comandos rápidos, não numa TUI |
| Plugin oh-my-zsh | CLI standalone é suficiente |
| Cross-platform (Linux/Windows) | macOS-only permite usar JXA e ferramentas BSD |
| Recurring tasks | Over-engineering pro caso de uso |
| Time tracking | Fora do escopo de task management simples |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TASK-01 | Phase 3 | Complete |
| TASK-02 | Phase 3 | Complete |
| TASK-03 | Phase 3 | Complete |
| TASK-04 | Phase 3 | Complete |
| TASK-05 | Phase 4 | Complete |
| TASK-06 | Phase 4 | Complete |
| TASK-07 | Phase 8 | Complete |
| PRIO-01 | Phase 4 | Complete |
| PRIO-02 | Phase 7 | Complete |
| LIST-01 | Phase 5 | Complete |
| LIST-02 | Phase 5 | Complete |
| LIST-03 | Phase 5 | Complete |
| LIST-04 | Phase 6 | Complete |
| VIEW-01 | Phase 7 | Complete |
| VIEW-02 | Phase 8 | Pending |
| VIEW-03 | Phase 8 | Pending |
| TAG-01 | Phase 6 | Complete |
| TAG-02 | Phase 6 | Complete |
| STOR-01 | Phase 2 | Complete |
| STOR-02 | Phase 2 | Complete |
| STOR-03 | Phase 1 | Complete |
| STOR-04 | Phase 2 | Complete |

**Coverage:**
- v1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0

---
*Requirements defined: 2026-04-02*
*Last updated: 2026-04-02 after roadmap creation*
