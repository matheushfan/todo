<!-- GSD:project-start source:PROJECT.md -->
## Project

**todolist-cli**

CLI de gerenciamento de tasks para o terminal, escrito 100% em shell/zsh puro sem dependências externas. Permite criar múltiplas listas com status customizáveis, visualização kanban inline com cores, prioridades, tags e filtros. Storage centralizado em `~/.todolist/` com namespaces por lista.

**Core Value:** Gerenciar tasks direto no terminal de forma rápida e visual, sem sair do fluxo de trabalho.

### Constraints

- **Linguagem**: Shell/Zsh puro — sem Python, Node, Go ou qualquer runtime externo
- **Dependências**: Zero — apenas utilitários POSIX padrão (sed, awk, grep, etc)
- **Plataforma**: macOS primário (zsh como shell padrão)
- **Storage**: JSON flat files em ~/.todolist/
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Runtime
| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| zsh | 5.9+ | Shell runtime, script engine | Default shell on macOS since Catalina. Richer than bash: associative arrays, better parameter expansion, autoload functions | HIGH |
| osascript -l JavaScript (JXA) | macOS built-in | JSON read/write/parse/filter | Built into every macOS. Full JSON.parse/JSON.stringify. Handles arrays, nesting, filtering natively. Zero install. Verified working. | HIGH |
| printf | POSIX built-in | Terminal output, column alignment | More portable and precise than echo. Supports format specifiers for alignment (%-20s). | HIGH |
### Data Layer
| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| JSON flat files | N/A | Task/list storage in ~/.todolist/ | Human-readable, natively parseable by JXA/osascript. One file per list namespace. | HIGH |
| osascript JXA | macOS built-in | JSON CRUD operations | Full JavaScript engine: JSON.parse(), array.filter(), array.push(), JSON.stringify(null, 2). Handles nested objects, arrays, escaping -- unlike sed/awk which fail on arrays (0% success rate). | HIGH |
| uuidgen | macOS built-in | Unique task IDs | Ships with macOS at /usr/bin/uuidgen. Generates RFC 4122 UUIDs. No need for homebrew or /dev/urandom hacks. | HIGH |
### Terminal Rendering
| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| ANSI escape codes ($'\033[...m') | N/A | Colors (priority indicators, status headers) | Direct control over exact colors. 256-color support in modern terminals. Simpler than tput for a project that targets macOS only. | HIGH |
| tput cols / tput lines | ncurses built-in | Terminal dimension detection | Reliable method to detect terminal width for responsive kanban layout. Falls back to 80 cols. | HIGH |
| printf with format specifiers | POSIX built-in | Column alignment in kanban view | %-Ns for left-aligned fixed-width cells. Must use ANSI-aware width calculation (strip escape codes before measuring). | HIGH |
### File Operations
| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| mkdir -p | POSIX built-in | Directory creation, atomic file locking | mkdir is atomic at kernel level -- only one process succeeds. Portable lock mechanism without flock (which is Linux-only). | HIGH |
| mktemp | POSIX built-in | Safe temp files for atomic writes | Write to temp, then mv to target. Prevents corruption on crash/interrupt. | HIGH |
| mv | POSIX built-in | Atomic file replacement | mv on same filesystem is atomic. Write-to-temp + mv = safe JSON updates. | HIGH |
### Shell Organization
| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| zsh autoload + fpath | zsh built-in | Modular function loading | Each command in its own file. Only loaded when called. Keeps main script small. Standard zsh pattern for large projects. | HIGH |
| zsh associative arrays (typeset -A) | zsh built-in | In-memory config, color maps, status mappings | Native hash maps in zsh. No need for temp files or subshell hacks. | HIGH |
| zsh parameter expansion | zsh built-in | String manipulation without external calls | ${var:l} lowercase, ${var:u} uppercase, ${var//pattern/replace}, ${var[(w)n]} word splitting. Avoids spawning sed/awk for simple transforms. | HIGH |
## The JSON Strategy: Why osascript JXA, Not sed/awk
### Option 1: sed/awk for JSON (REJECTED)
- Simple key-value updates: 100% success
- Nested updates (2 levels): 75% success
- Array operations (add/remove/filter): 0% success
- Cannot validate output is valid JSON
- Tasks are stored in arrays -- this approach is dead on arrival
### Option 2: Embedded awk JSON parser (JSON.awk) (REJECTED)
- Requires bundling a ~400-line awk script
- Parsing only -- no modification/serialization
- Complex callback-based API
- Tested mainly with gawk; macOS ships BSD awk
### Option 3: osascript -l JavaScript (JXA) (CHOSEN)
- Full JSON.parse() and JSON.stringify()
- Array operations: filter, map, push, splice -- all native
- Nested object traversal with dot notation
- Pretty-printing with JSON.stringify(obj, null, 2)
- Can read files natively via Application.currentApplication().read()
- Ships with every macOS since Yosemite (2014)
- Verified working on current macOS (2026-04-02)
### JXA Usage Patterns
## ANSI Color Strategy
# Color constants (define once at top of script)
# Priority color map
## Kanban Column Layout Strategy
# Minimum 20 chars per column; if too narrow, fall back to list view
## What NOT to Use
| Technology | Why Not |
|------------|---------|
| jq | External dependency. The whole point is zero deps. osascript JXA does everything jq does. |
| python3 | External runtime. Not guaranteed on all macOS installs (removed from some Xcode CLT versions). |
| sed/awk for JSON writes | 0% success rate on array operations. Tasks live in arrays. |
| flock | Linux-only. Not available on macOS. Use mkdir for atomic locking. |
| tput for colors | Slower (terminfo lookup per call). Over-engineered for macOS-only target. ANSI codes are universal in modern terminals. |
| ncurses / dialog | External dependency. Interactive TUI is explicitly out of scope. |
| column command | BSD version on macOS is limited (no --output-separator, no JSON mode). printf is more controllable for kanban layout. |
| bash | macOS ships bash 3.2 (2007, GPL2). Zsh 5.9 is default and far more capable. |
| Homebrew anything | Violates zero-dependency constraint. |
## File Structure
## Data Format
## Installation
## Sources
- [macOS JXA JSON parsing](https://macblog.org/parse-json-command-line-mac/) - Verified approach for osascript JSON handling
- [JXA Cookbook](https://github.com/JXA-Cookbook/JXA-Cookbook/wiki/Using-JavaScript-for-Automation) - JavaScript for Automation reference
- [Sed JSON manipulation limitations](https://karandeepsingh.ca/posts/sed-json-manipulation-without-jq/) - 0% success on arrays
- [JSON.awk](https://github.com/step-/JSON.awk) - Pure awk parser (evaluated, rejected)
- [zsh autoload functions](https://dev.to/lukeojones/1up-your-zsh-abilities-by-autoloading-your-own-functions-2ngp)
- [zsh parameter expansion](https://zsh.sourceforge.io/Doc/Release/Expansion.html)
- [ANSI escape codes reference](https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124)
- [tput vs ANSI codes](https://www.codequoi.com/en/coloring-terminal-text-tput-and-ansi-escape-sequences/)
- [Terminal dimension detection](https://www.baeldung.com/linux/bash-console-geometry)
- [Atomic mkdir locking](https://mywiki.wooledge.org/BashFAQ/045)
- [todo.txt-cli](https://github.com/todotxt/todo.txt-cli) - Reference shell-based task manager (5.8k stars)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
