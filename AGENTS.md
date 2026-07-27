# AGENTS.md

## Project Overview

**trustrail.el** is an Emacs Lisp package that provides a `tabulated-list-mode` buffer for inspecting installed Emacs packages. It wraps `package.el` internals into a read-only, sortable table UI.

- Entry point: `M-x trustrail-list-packages`
- Single-file package: `trustrail.el`
- Requires Emacs 27.1+

## Architecture

The package follows standard Emacs package conventions:

1. **Data layer** — `trustrail--installed-packages` reads from `package-alist` (initializing `package.el` if needed) and returns a sorted copy.
2. **Transform** — `trustrail--tabulated-entry` converts each package descriptor into a vector suitable for `tabulated-list-mode`.
3. **UI** — `trustrail-package-list-mode` (derived from `tabulated-list-mode`) defines column layout; `trustrail-list-packages` is the interactive command that assembles and displays the buffer.

Private helpers use the `trustrail--` prefix; public API uses `trustrail-`.

## Conventions

- **Naming**: All symbols prefixed with `trustrail-`. Internal functions use double-dash (`trustrail--`).
- **Autoloads**: Only the mode (`trustrail-package-list-mode`) and the interactive command (`trustrail-list-packages`) are autoloaded.
- **Docstrings**: Every function has a one-line docstring. Parameter names are capitalized in docstrings (e.g., `PKG`, `DESC`).
- **Lexical binding**: File header includes `lexical-binding: t`.
- **Buffer naming**: Use `defconst` for buffer name constants (see `trustrail-buffer-name`).
- **Customization group**: Defined via `defgroup trustrail` under `:group 'tools`.

## Development Workflow

```bash
# Byte-compile (from project root)
emacs -batch -f batch-byte-compile trustrail.el

# Load interactively for testing
emacs -Q -L . -l trustrail -e '(trustrail-list-packages)'
```

No external build system, test framework, or CI is configured yet. Changes are validated by byte-compilation and manual `M-x trustrail-list-packages`.

## Key Patterns

- Extract accessors for package data (`trustrail--package-name`, `trustrail--package-version`, etc.) rather than inline `car`/`cadr` calls — keeps the tabulated-entry builder readable.
- Defensive nil checks in accessors (`trustrail--package-version` returns `"unknown"` if desc is nil).
- `pop-to-buffer` used over `switch-to-buffer` to respect user display rules.

## Adding New Columns

To add a column to the package list:
1. Add an accessor function (`trustrail--package-<field>`).
2. Add the column spec to `tabulated-list-format` in `trustrail-package-list-mode`.
3. Include the value in the vector returned by `trustrail--tabulated-entry`.

