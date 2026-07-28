# trustrail.el

An Emacs **major mode** that displays your installed `package.el` packages in a sortable, read-only table buffer.

## Features

- Lists all packages installed via `package.el` with their **name**, **version**, **source**, **summary**, and **install directory**
- **Source column** classifies each package as `configured`, `dependency`, `manual`, or `unknown`
- Sortable columns — click a column header or use `tabulated-list-mode` keybindings to sort
- Auto-detects your config file from `user-init-file` and follows `org-babel-load-file`, `load`, and `load-file` includes
- Supports both `.org` (literate) and `.el` config files
- Read-only buffer that respects your display rules (`pop-to-buffer`)

## Requirements

- Emacs **27.1** or later

## Installation

### Manual

Clone this repository and add it to your load path:

```elisp
(add-to-list 'load-path "/path/to/trustrail.el")
(require 'trustrail)
```

### use-package (Emacs 30+, built-in `:vc`)

Emacs 30 ships `use-package` with `:vc` support — no extra package manager needed:

```elisp
(use-package trustrail
  :vc (:url "https://github.com/systemhalted/trustrail.el" :branch "main")
  :commands trustrail-list-packages)
```

### use-package (Emacs < 30, local clone)

Clone this repository 
```elisp
(use-package trustrail
  :load-path "/path/to/trustrail.el"
  :commands trustrail-list-packages)
```

### straight.el

```elisp
(use-package trustrail
  :straight (:host github :repo "systemhalted/trustrail.el")
  :commands trustrail-list-packages)
```

## Usage

```
M-x trustrail-list-packages
```

This opens the `*TrustRail Packages*` buffer showing a table like:

| Package       | Version | Source     | Summary                          | Directory                          |
|---------------|---------|------------|----------------------------------|------------------------------------|
| magit         | 3.3.0   | configured | A Git porcelain inside Emacs     | ~/.emacs.d/elpa/magit-3.3.0/      |
| dash          | 2.19.1  | dependency | A modern list library            | ~/.emacs.d/elpa/dash-2.19.1/      |
| use-package   | 2.4.5   | manual     | A configuration macro for …      | ~/.emacs.d/elpa/use-package-2.4.5/ |

Standard `tabulated-list-mode` keys apply, plus:

| Key   | Command                     | Action                              |
|-------|-----------------------------|-------------------------------------|
| `g`   | `trustrail-refresh`         | Rebuild the package list            |
| `/`   | `trustrail-filter`          | Filter by name or summary substring |
| `C`   | `trustrail-filter-clear`    | Clear the active filter             |
| `RET` | `trustrail-describe-package`| Describe the package at point       |
| `d`   | `trustrail-open-directory`  | Open install directory in Dired     |
| `h`   | `trustrail-visit-homepage`  | Open package homepage in browser    |
| `S`   | *(built-in)*                | Sort by column                      |
| `q`   | *(built-in)*                | Quit the buffer                     |

## Customization

All symbols live under the `trustrail` customization group:

```
M-x customize-group RET trustrail RET
```

### Source column

Each package is classified as:

| Source       | Meaning |
|--------------|---------|
| `configured` | Declared via `use-package` or `require` in your config file |
| `dependency` | Pulled in as a requirement of another installed package |
| `manual`     | Installed in `package-user-dir` but not in config or a dependency |
| `unknown`    | Source could not be determined |

### Config file detection

By default, trustrail reads `user-init-file` (e.g. `~/.emacs.d/init.el`) and
follows `org-babel-load-file`, `load`, and `load-file` calls to discover the
real config files. Both `.org` (literate) and `.el` formats are supported.

To override auto-detection, set `trustrail-user-config-files`:

```elisp
(setq trustrail-user-config-files
      '("~/.emacs.d/config.org"
        "~/.emacs.d/extra.el"))
```

## Development

```bash
# Byte-compile
emacs -batch -f batch-byte-compile trustrail.el

# Load interactively for testing
emacs -Q -L . -l trustrail -e '(trustrail-list-packages)'
```

## Roadmap

See `ROADMAP.md` for the phased feature plan from MVP to v1.0.

## License

Licensed under the [GNU General Public License v3.0](LICENSE).
