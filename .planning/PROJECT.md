# todolist-cli

## What This Is

CLI de gerenciamento de tasks para o terminal, escrito 100% em shell/zsh puro sem dependências externas. Permite criar múltiplas listas com status customizáveis, visualização kanban inline com cores, prioridades, tags e filtros. Storage centralizado em `~/.todolist/` com namespaces por lista.

## Core Value

Gerenciar tasks direto no terminal de forma rápida e visual, sem sair do fluxo de trabalho.

## Current State

**Shipped:** v0.2 Interactive Experience (2026-04-03)
**LOC:** ~3,062 zsh | **Commits:** 50 | **Files:** 60+

Fully functional CLI with:
- CRUD completo (add, edit, rm, ls)
- Multi-list management with independent namespaces
- Custom statuses per list
- Priority system (high/medium/low) with color coding
- Free-form tags with filtering
- Kanban board view with responsive layout
- Bulk operations (done/move/rm)
- Zero external dependencies — pure zsh + macOS built-ins

## Requirements

### Validated

- ✓ Criar, editar e remover tasks via CLI — v0.1
- ✓ Múltiplas listas com fácil switch entre elas — v0.1
- ✓ Status customizáveis por lista — v0.1
- ✓ Visualização kanban inline (colunas lado a lado) — v0.1
- ✓ Prioridades high/medium/low com cores (red/yellow/green) — v0.1
- ✓ Tags/labels livres nas tasks — v0.1
- ✓ Filtro por status e prioridade — v0.1
- ✓ Storage centralizado em ~/.todolist/ com namespaces — v0.1
- ✓ Zero dependências externas — shell/zsh puro — v0.1

### Active

- [ ] Filtro por tag (SRCH-01)
- [ ] Busca por texto livre em todos os campos (SRCH-02)
- [ ] Filtro cross-list (SRCH-03)
- [ ] Zsh tab completions para comandos, listas e tags (UX-01)
- [ ] Help system com exemplos por comando (UX-02)
- [ ] NO_COLOR env var support (UX-03)
- [ ] Export/import de listas (UX-04)

### Out of Scope

- Due dates / prazos — complexidade desnecessária, o foco é simplicidade
- Sincronização com serviços externos (Todoist, Linear, etc) — manter offline-first e simples
- Interface TUI via ncurses — usando zsh read/zle nativo em vez de ncurses externo
- Plugin oh-my-zsh formal — CLI standalone é suficiente
- Cross-platform (Linux/Windows) — macOS-only permite usar JXA e ferramentas BSD
- Recurring tasks — over-engineering pro caso de uso
- Time tracking — fora do escopo de task management simples

## Context

- Usuário é desenvolvedor que vive no terminal e quer trackear tasks sem abrir outra ferramenta
- Shell/zsh puro garante zero dependências e máxima portabilidade no macOS
- Storage em JSON plano dentro de ~/.todolist/ — parseado via osascript JXA (built-in macOS)
- Kanban inline no terminal é o diferencial visual — colunas alinhadas com ANSI colors
- Cada lista é um namespace independente com seus próprios status customizados
- Performance é prioridade — operações devem ser instantâneas
- Tech stack: zsh 5.9+, osascript JXA para JSON, ANSI escape codes para cores, printf para alignment

## Constraints

- **Linguagem**: Shell/Zsh puro — sem Python, Node, Go ou qualquer runtime externo
- **Dependências**: Zero — apenas utilitários POSIX padrão + macOS built-ins (osascript, uuidgen)
- **Plataforma**: macOS primário (zsh como shell padrão)
- **Storage**: JSON flat files em ~/.todolist/

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Shell/Zsh puro | Zero dependências, máxima portabilidade, performance instantânea | ✓ Good — startup instantâneo, sem overhead |
| osascript JXA para JSON | Full JSON.parse/stringify built-in no macOS, 100% array support | ✓ Good — resolveu limitações de sed/awk |
| Storage centralizado ~/.todolist/ | Único lugar pra todas as listas, sem poluir diretórios de projeto | ✓ Good |
| Atomic write-to-temp + mv | Previne corrupção em crash/interrupt | ✓ Good |
| zsh autoload/fpath | Cada comando em arquivo separado, carregado sob demanda | ✓ Good — modular e extensível |
| Priority em inglês (high/medium/low) | Consistência com CLI em inglês | ✓ Good — renomeado de PT em quick task |
| Single JXA call para kanban grouping | Agrupa tasks por status em uma chamada, evita N+1 | ✓ Good |
| Truncar plain text antes de colorizar | Evita quebrar escape sequences ANSI | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-03 after v0.2 milestone complete*
