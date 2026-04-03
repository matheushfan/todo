# todo

A kanban-style task manager that lives in your terminal. Pure zsh, zero dependencies.

```
┌─── todo ──────────────┬──── doing ─────────────┬──── done ──────────────┐
│ Fix auth middleware    │ Build payment API      │ Setup CI pipeline      │
│ [high]                │ [medium]               │ [low]                  │
│                       │ Write API docs         │ Design landing page    │
│                       │ [low] #docs            │ [medium] #design       │
└───────────────────────┴────────────────────────┴────────────────────────┘
```

## Features

- **Kanban board** — inline columns per status, right in the terminal
- **Multiple lists** — one per project/context, switch with a single command
- **Custom statuses** — each list defines its own workflow (not just todo/doing/done)
- **Priorities** — high/medium/low with color coding (red/yellow/green)
- **Tags** — free-form labels on any task
- **Filters** — by status, priority
- **Bulk operations** — done/move/rm multiple tasks at once
- **Zero dependencies** — 100% zsh + macOS built-ins. No Python, no Node, no Go.

## Install

### One-liner

```bash
zsh -c "$(curl -fsSL https://raw.githubusercontent.com/matheushfan/todo/master/install.sh)"
```

### Manual

```bash
git clone https://github.com/matheushfan/todo.git ~/.todo-cli
chmod +x ~/.todo-cli/bin/todo
ln -sf ~/.todo-cli/bin/todo /usr/local/bin/todo
```

### Or add to PATH

Add to your `~/.zshrc`:

```bash
export PATH="$HOME/.todo-cli/bin:$PATH"
```

### Verify

```bash
todo version
# todo v0.1.0
```

## Usage

### Tasks

```bash
todo add "Fix the login bug"                  # create task
todo add -p high "Deploy hotfix"              # with priority
todo add -t backend,urgent "Refactor auth"    # with tags

todo ls                                       # list all tasks
todo ls -s doing                              # filter by status
todo ls -p high                               # filter by priority

todo edit abc1 "Updated title"                # edit (ID prefix match)
todo rm abc1                                  # remove
```

### Workflow

```bash
todo move abc1 doing                          # change status
todo done abc1                                # mark completed
todo priority abc1 high                       # set priority
```

### Kanban Board

```bash
todo                                          # show board (default command)
todo board                                    # same thing
```

Columns are one per status. Auto-falls back to stacked list view when the terminal is too narrow.

### Multiple Lists

```bash
todo list create work                         # create list
todo list create personal
todo list switch work                         # switch active
todo list                                     # show all lists
```

All task commands (`add`, `ls`, `board`, etc.) operate on the active list.

### Custom Statuses

```bash
todo status                                   # show current statuses
todo status add "in-review"                   # add status
todo status rm "in-review"                    # remove (only if no tasks use it)
```

Default statuses: `todo`, `doing`, `done`. Each list has its own.

### Tags

```bash
todo tag add abc1 backend                     # add tag
todo tag rm abc1 backend                      # remove tag
```

### Bulk Operations

```bash
todo bulk done abc1 def2 ghi3                 # mark multiple done
todo bulk move doing abc1 def2                # move multiple
todo bulk rm abc1 def2                        # remove multiple
todo bulk done --status todo                  # all tasks in a status
todo bulk done --all                          # all tasks
```

## Storage

Data lives in `~/.todolist/` (override with `TODOLIST_DATA` env var):

```
~/.todolist/
  config.json              # active list
  lists/
    default/
      tasks.json           # task data
      config.json          # list statuses
    work/
      tasks.json
      config.json
```

JSON flat files. Human-readable. Back up by copying the directory.

## Requirements

- **macOS** with zsh 5.9+ (default since Catalina)
- That's it.

## How it works

- Entry point: `bin/todo` (~40 lines) — sets up autoload, dispatches subcommands
- Commands: `commands/td-*` — one file per command, loaded on demand via zsh `fpath`
- Libraries: `lib/_td_*` — storage (JXA JSON engine), colors (ANSI), board (kanban renderer)
- Storage: `osascript -l JavaScript` (JXA) for JSON parsing — built into every Mac since 2014

No external tools. No `jq`. No `python`. No `node`. Just zsh and what macOS ships with.

## Tests

```bash
# run all tests
for t in tests/test_*.zsh; do zsh "$t"; done

# run specific suite
zsh tests/test_board.zsh
zsh tests/test_storage.zsh
```

275 tests across 12 suites.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
