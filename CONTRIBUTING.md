# Contributing

Thanks for considering contributing to todo!

## Getting Started

1. Fork the repo
2. Clone your fork
3. Create a branch: `git checkout -b my-feature`
4. Make your changes
5. Run tests: `for t in tests/test_*.zsh; do zsh "$t"; done`
6. Commit: `git commit -m "feat: add my feature"`
7. Push: `git push origin my-feature`
8. Open a Pull Request

## Development

### Prerequisites

- macOS with zsh 5.9+
- That's it. No build tools, no package managers.

### Project Structure

```
bin/todo          Entry point (~40 lines) — bootstrap + dispatch
commands/td-*     One file per command, autoloaded via fpath
lib/_td_*         Shared libraries (storage, colors, board renderer)
tests/test_*.zsh  Test suites (one per feature area)
```

### Adding a Command

1. Create `commands/td-mycommand` (no extension)
2. Write the function body directly (no wrapping function — zsh autoload convention)
3. Add tests in `tests/test_myfeature.zsh`
4. Update help text in `lib/_td_help`

### Running Tests

```bash
# all tests
for t in tests/test_*.zsh; do zsh "$t"; done

# specific suite
zsh tests/test_board.zsh
```

Tests use a custom harness (`tests/test_helpers.zsh`) with `assert_eq`, `assert_contains`, and `assert_exit_code`. Each test creates an isolated temp directory — never touches `~/.todolist/`.

### Conventions

- **Zero external dependencies.** Everything must work with zsh built-ins and macOS system tools only.
- **No `jq`, `python`, `node`, `brew` packages.** JSON operations use `osascript -l JavaScript` (JXA).
- **Prefix conventions:** `_td_` for internal lib functions, `td-` for user-facing commands.
- **Atomic writes:** All file writes use temp file + `mv` pattern. Never write directly to data files.
- **Security:** Pass data to JXA via environment variables, never string interpolation.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new command
fix: handle empty task list
test: add edge case for bulk operations
docs: update README examples
refactor: simplify board rendering
```

## Reporting Bugs

Open an issue with:

1. What you did
2. What you expected
3. What happened instead
4. Your zsh version (`zsh --version`)

## Feature Requests

Open an issue describing the use case, not just the solution. We value simplicity — features must justify their complexity.
