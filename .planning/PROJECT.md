# todolist-cli

## What This Is

CLI de gerenciamento de tasks para o terminal, escrito 100% em shell/zsh puro sem dependências externas. Permite criar múltiplas listas com status customizáveis, visualização kanban inline com cores, prioridades, tags e filtros. Storage centralizado em `~/.todolist/` com namespaces por lista.

## Core Value

Gerenciar tasks direto no terminal de forma rápida e visual, sem sair do fluxo de trabalho.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Criar, editar e remover tasks via CLI
- [ ] Múltiplas listas com fácil switch entre elas
- [ ] Status customizáveis por lista (o usuário define os status de cada lista)
- [ ] Visualização kanban inline (colunas lado a lado no terminal)
- [ ] Prioridades Alta/Média/Baixa com cores (vermelho/amarelo/verde)
- [ ] Tags/labels livres nas tasks
- [ ] Busca e filtro por status, prioridade, tag e texto
- [ ] Storage centralizado em ~/.todolist/ com namespaces
- [ ] Zero dependências externas — shell/zsh puro

### Out of Scope

- Due dates / prazos — complexidade desnecessária pro v1, o foco é simplicidade
- Sincronização com serviços externos (Todoist, Linear, etc) — manter offline-first e simples
- Interface TUI interativa (tipo ncurses) — o valor é nos comandos rápidos, não numa TUI
- Plugin oh-my-zsh formal — CLI standalone é suficiente, aliases o usuário cria se quiser

## Context

- Usuário é desenvolvedor que vive no terminal e quer trackear tasks sem abrir outra ferramenta
- Shell/zsh puro garante zero dependências e máxima portabilidade no macOS
- Storage em JSON plano dentro de ~/.todolist/ — simples de parsear com ferramentas shell
- Kanban inline no terminal é o diferencial visual — colunas alinhadas com ANSI colors
- Cada lista é um namespace independente com seus próprios status customizados
- Performance é prioridade — operações devem ser instantâneas

## Constraints

- **Linguagem**: Shell/Zsh puro — sem Python, Node, Go ou qualquer runtime externo
- **Dependências**: Zero — apenas utilitários POSIX padrão (sed, awk, grep, etc)
- **Plataforma**: macOS primário (zsh como shell padrão)
- **Storage**: JSON flat files em ~/.todolist/

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Shell/Zsh puro | Zero dependências, máxima portabilidade, performance instantânea | — Pending |
| Storage centralizado ~/.todolist/ | Único lugar pra todas as listas, sem poluir diretórios de projeto | — Pending |
| Status custom por lista | Flexibilidade — cada contexto tem seu fluxo diferente | — Pending |
| JSON como formato de dados | Parseable com ferramentas shell, human-readable | — Pending |

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
*Last updated: 2026-04-02 after initialization*
