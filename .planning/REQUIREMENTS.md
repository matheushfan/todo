# Requirements: todolist-cli

**Defined:** 2026-04-03
**Core Value:** Gerenciar tasks direto no terminal de forma rapida e visual, sem sair do fluxo de trabalho.

## v1.1 Requirements

Requirements for v1.1 Interactive Experience. Each maps to roadmap phases.

### Interactive Engine

- [ ] **TUI-01**: User can enter interactive board view via `td ui` command
- [ ] **TUI-02**: User can navigate between tasks with j/k (up/down) and h/l or arrows
- [ ] **TUI-03**: User can cycle task status forward with `s` key (status cycling)
- [ ] **TUI-04**: User can mark task done with `d`, delete with `x` from interactive view
- [ ] **TUI-05**: User can open task ref URL in browser with `o` key
- [ ] **TUI-06**: Interactive view renders using zcurses (zsh/curses built-in module)
- [ ] **TUI-07**: Terminal state is cleanly restored on any exit (Ctrl+C, q, crash)

### Data & Detail

- [ ] **DATA-01**: User can view full task details via `td show <id>`
- [ ] **DATA-02**: User can attach a URL/ref to any task via `td ref <id> <url>`
- [ ] **DATA-03**: User can archive completed tasks via `td archive`
- [ ] **DATA-04**: User can list archived tasks via `td archive ls`
- [ ] **DATA-05**: Archive stores tasks in separate archive.json (not deleted, consultable)

### UX & Polish

- [ ] **UX-05**: User can view tasks in checkbox mode ([ ]/[x]) for simple lists
- [ ] **UX-06**: User can see pending task count via `td summary` command
- [x] **UX-07**: Interactive mode shows help overlay with `?` key listing all keybindings
- [x] **UX-08**: Interactive view handles terminal resize gracefully (redraw on SIGWINCH)

## Future Requirements

Deferred to v1.2+. Tracked but not in current roadmap.

### Search & Filtering (from v1.0 backlog)

- **SRCH-01**: User can filter tasks by tag
- **SRCH-02**: User can search tasks by free text across all fields
- **SRCH-03**: User can filter across multiple lists simultaneously

### Completions & Integration

- **UX-01**: Zsh tab completions for commands, list names, and tags
- **UX-02**: Help system with usage examples per command
- **UX-03**: NO_COLOR environment variable support
- **UX-04**: Export/import lists to portable format

### Interactive Advanced

- **TUI-08**: User can add a new task inline from interactive view
- **TUI-09**: User can edit task title inline from interactive view
- **TUI-10**: Mouse click support for task selection

## Out of Scope

| Feature | Reason |
|---------|--------|
| Due dates / prazos | Complexidade desnecessaria, foco e simplicidade |
| Sync com servicos externos | Manter offline-first e simples |
| ncurses externo / dependency | Usar zcurses built-in do zsh, zero deps |
| Cross-platform (Linux/Windows) | macOS-only permite usar JXA e zcurses |
| Drag-and-drop / mouse drag | Over-engineering para terminal |
| Multi-select no interactive | Complexidade de UX, bulk ops via CLI e suficiente |
| Recurring tasks | Over-engineering pro caso de uso |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DATA-01 | Phase 9 | Pending |
| DATA-02 | Phase 9 | Pending |
| DATA-03 | Phase 10 | Pending |
| DATA-04 | Phase 10 | Pending |
| DATA-05 | Phase 10 | Pending |
| UX-06 | Phase 11 | Pending |
| TUI-01 | Phase 12 | Pending |
| TUI-06 | Phase 12 | Pending |
| TUI-07 | Phase 12 | Pending |
| TUI-02 | Phase 13 | Pending |
| TUI-03 | Phase 13 | Pending |
| TUI-04 | Phase 13 | Pending |
| TUI-05 | Phase 13 | Pending |
| UX-05 | Phase 14 | Pending |
| UX-07 | Phase 14 | Complete |
| UX-08 | Phase 14 | Complete |

**Coverage:**
- v1.1 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-04-03*
*Last updated: 2026-04-03 after v1.1 roadmap creation*
