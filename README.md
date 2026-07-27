# trustrail.el

An Emacs **major mode** that displays your installed `package.el` packages in a sortable, read-only table buffer.

## Features

- Lists all packages installed via `package.el` with their **name**, **version**, **summary**, and **install directory**
- Sortable columns — click a column header or use `tabulated-list-mode` keybindings to sort
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

| Package       | Version | Summary                          | Directory                          |
|---------------|---------|----------------------------------|------------------------------------|
| magit         | 3.3.0   | A Git porcelain inside Emacs     | ~/.emacs.d/elpa/magit-3.3.0/      |
| use-package   | 2.4.5   | A configuration macro for …      | ~/.emacs.d/elpa/use-package-2.4.5/ |

Standard `tabulated-list-mode` keys apply (e.g., `S` to sort by column, `q` to quit).

## Customization

All symbols live under the `trustrail` customization group:

```
M-x customize-group RET trustrail RET
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
