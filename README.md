# todo

A kanban-style task manager that lives in your terminal. Pure zsh, zero dependencies.

```
  main   19 todo · 3 doing · 4 done                       26 tasks · 2 lists
  TODO                 19 │  DOING                 3 │  DONE                 4
──────────────────────────┼──────────────────────────┼──────────────────────────
 ▇ Fix auth token refresh │ ▇ Refactor storage layer │ ✓ Storage lock design
   4c1a  api  6h  ↗       │   2a3f  api db  3h       │   aa71  core  1d
 ▄ Write migration notes  │ ▄ Theme engine plus 256… │ ✓ Width primitives
   9b02  docs  4h         │   b8c7  ui  3h           │   c604  core  1d
 ▁ Sidebar list counts    │                          │
   77a4  ui  2d           │                          │
──────────────────────────┴──────────────────────────┴──────────────────────────
```

Priority reads as a scale — `▇` high, `▄` medium, `▁` low — and falls back to
`!` `~` `.` where Unicode is not available.

## Features

- **Kanban board** — columns per status, right in the terminal
- **Interactive board** — TUI with keyboard navigation (`todo ui`)
- **Checkbox mode** — simple `[ ]/[x]` view for todo/done lists
- **Multiple lists** — one per project/context, switch with a single command
- **Custom statuses** — each list defines its own workflow
- **Priorities, tags and filters** — by status or priority
- **Detail view** — every field of a task with `todo show`
- **Reference URLs** — attach Linear, GitHub or any link; clickable where the
  terminal supports OSC-8 hyperlinks
- **Archive** — set completed tasks aside without deleting them
- **Summary** — proportional bars, plus a compact form for your shell prompt
- **Bulk operations** — done/move/rm several tasks at once
- **Safe under concurrency** — writes are locked, so two terminals cannot
  silently clobber each other
- **Themeable** — `nocturne` (dark) and `paper` (light), degrading 24-bit →
  256 → 16 → no colour, and honouring `NO_COLOR`
- **Correct with any text** — accents, CJK and emoji stay aligned, because
  columns are measured in display width rather than characters
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
# todo v0.3.0
```

## Usage

### Interactive Mode

```bash
todo ui                                       # open interactive board
todo ui --checkbox                            # checkbox mode (simple lists)
```

**Keybindings:**

| Key | Action |
|-----|--------|
| `j/k` | Move up/down |
| `h/l` | Move left/right between columns |
| `s` | Cycle status (todo → doing → done) |
| `d` | Mark done |
| `x` | Delete task |
| `o` | Open ref URL in browser |
| `?` | Help overlay |
| `q` | Quit |

Arrow keys also work for navigation.

### Tasks

```bash
todo add "Fix the login bug"                  # create task
todo add -p high "Deploy hotfix"              # with priority
todo add -t backend,urgent "Refactor auth"    # with tags
todo add -r https://linear.app/... "Fix bug"  # with reference URL

todo ls                                       # list all tasks
todo ls -s doing                              # filter by status
todo ls -p high                               # filter by priority

todo edit abc1 "Updated title"                # edit (ID prefix match)
todo rm abc1                                  # remove
```

### Detail View & References

```bash
todo show abc1                                # show all task fields
todo ref abc1 https://linear.app/issue/123    # attach URL
todo ref abc1                                 # show current ref
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

### Archive

```bash
todo archive                                  # archive all done tasks
todo archive ls                               # list archived tasks
todo archive undo abc1                        # restore from archive
```

Archived tasks are stored separately — they don't appear in `ls`, `board`, or `bulk`.

### Summary

```bash
todo summary                                  # bars per status, % complete
todo summary --oneline                        # todo:19 doing:3 done:4
todo summary --glyph                          # main ▇19 ▄3 ✓4
```

Add to `~/.zshrc` for startup info:

```bash
todo summary --oneline 2>/dev/null
```

The compact forms never emit colour unless `CLICOLOR_FORCE` is set, so they are
safe to embed in a prompt.

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
      archive.json         # archived tasks
      config.json          # list statuses
    work/
      tasks.json
      archive.json
      config.json
```

JSON flat files. Human-readable. Back up by copying the directory.

## Customization

| Variable | Effect |
|----------|--------|
| `TODOLIST_DATA` | Where data lives (default `~/.todolist`) |
| `TD_THEME` | `nocturne` (dark, default) or `paper` (light) |
| `TD_COLOR_DEPTH` | Force `24`, `8`, `4` or `0`; otherwise detected |
| `TD_ASCII` | Set to any value to draw with ASCII instead of Unicode |
| `NO_COLOR` | Honoured — disables colour entirely |
| `CLICOLOR_FORCE` | Keep colour even when piping |
| `TD_LOCK_TIMEOUT` | Seconds to wait for a write lock (default 10) |

Colour degrades on its own: 24-bit → 256 → 16 → none. Apple's Terminal.app is
pinned to 256 because it advertises truecolor it cannot actually render.

## Requirements

- **macOS** with zsh 5.9+ (default since Catalina)
- That's it.

## How it works

- Entry point: `bin/todo` — sets up autoload, installs the lock traps, dispatches subcommands
- Commands: `commands/td-*` — one file per command, loaded on demand via zsh `fpath`
- Libraries: `lib/_td_*` — `_td_ui` (measurement, theme, glyphs), `_td_storage`
  (JXA JSON engine), `_td_lock` (write locking), `_td_board` (kanban renderer),
  `_td_interactive` (TUI)
- Storage: `osascript -l JavaScript` (JXA) for JSON parsing — built into every Mac since 2014

Two details worth knowing if you read the source. Text is measured with zsh's
own display width, `${(m)#s}`, so CJK counts two columns and combining marks
count zero — that is why the board stays aligned through emoji and accents.
And the rendering helpers return through `REPLY` rather than stdout, because
`$(...)` forks a subshell per call, which cost 2ms per cell and made a large
board take a full second to lay out.

No external tools. No `jq`. No `python`. No `node`. Just zsh and what macOS ships with.

## Tests

```bash
# run all tests
for t in tests/test_*.zsh; do zsh "$t"; done

# run specific suite
zsh tests/test_board.zsh
zsh tests/test_storage.zsh
```

346 tests across 14 suites.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
