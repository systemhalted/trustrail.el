# trustrail.el Roadmap

This roadmap turns the MVP into a practical package-audit tool while keeping the project simple, fast, and idiomatic for Emacs.

## Product Direction

- Keep `trustrail-list-packages` as the entry point.
- Preserve a read-only, sortable `tabulated-list-mode` UX.
- Add package metadata and trust signals in layers.
- Avoid heavy dependencies; prefer built-in Emacs libraries.

## Current State (MVP)

Completed:
- Installed package listing from `package-alist`
- Columns: Package, Version, Summary, Directory
- Sortable table and dedicated major mode

Gaps:
- No filtering/search UX in the buffer
- No trust/security metadata (archive, signature state, source URL)
- No package actions (visit homepage, describe package)
- No tests or CI

## Phase 1: Usability Foundation (v0.1)

Goal: Make the listing easier to explore during daily use.

Planned features:
- Add lightweight in-buffer filtering (name/summary substring)
- Add refresh command (`g`) to rebuild entries
- Add keybindings for common actions (`RET` describe package, `q` quit)
- Persist last sort key and filter per session

Deliverables:
- New interactive commands in `trustrail-package-list-mode`
- Mode map with discoverable key hints in docstring/README

Exit criteria:
- User can open, filter, refresh, and inspect packages without leaving the buffer

## Phase 2: Metadata Expansion (v0.2)

Goal: Expand package context for better reporting.

Planned features:
- New columns: Archive, Maintainer, Homepage URL
- Defensive extraction from `package-desc-extras`
- Graceful fallback values (`""` or `"built-in"`)
- Optional column-width customization via defcustoms

Deliverables:
- Accessor helpers: `trustrail--package-archive`, `trustrail--package-maintainer`, `trustrail--package-url`
- Updated `tabulated-list-format` and entry builder

Exit criteria:
- Table shows reliable metadata for both archive-installed and built-in packages

## Phase 3: Trust Signals (v0.3)

Goal: Introduce the first security/trust indicators.

Planned features:
- Add trust status column (e.g., signed/unsigned/unknown)
- Flag packages from non-standard sources
- Optional "only show risky packages" filter
- Visual cues using faces for warning statuses

Deliverables:
- Trust evaluation helpers with clear rule comments
- Basic risk legend in mode help or README

Exit criteria:
- User can quickly identify potentially risky package entries

## Phase 4: Actionable Workflows (v0.4)

Goal: Turn report rows into actionable audit tasks.

Planned features:
- Row actions: open package homepage, open install directory, copy report line
- Export commands: Markdown and CSV report from current view
- Buffer command to show details pane for selected package

Deliverables:
- `trustrail-export-markdown` and `trustrail-export-csv`
- Action commands bound in mode map with confirmations where needed

Exit criteria:
- User can produce and share a package report without manual copy/paste

## Phase 5: Reliability and Quality (v0.5)

Goal: Stabilize behavior and guard against regressions.

Planned features:
- ERT unit tests for accessors and transforms
- ERT integration tests for tabulated entries shape
- Byte-compile check in CI (GitHub Actions)
- Linting/checkdoc pass for public API and docstrings

Deliverables:
- `test/trustrail-test.el`
- CI workflow running tests on Emacs 27.1+ and latest stable

Exit criteria:
- Changes are validated automatically with repeatable tests

## Phase 6: Packaging and Release (v1.0)

Goal: Make trustrail ready for broad use and contribution.

Planned features:
- Finalize user docs and examples
- Add changelog and release process notes
- Add contribution guide and issue templates
- Prepare MELPA-friendly metadata and versioning flow

Deliverables:
- `CHANGELOG.md`, `CONTRIBUTING.md`, expanded `README.md`
- Tagged v1.0 release notes

Exit criteria:
- New users can install, use, and contribute with minimal setup friction

## Backlog (Post-1.0)

- Asynchronous data refresh for large package sets
- Package diff reports between machines/snapshots
- Optional integration with `package-vc` metadata
- Optional transient menu for commands

## Suggested Milestones

- Milestone A: v0.1 + v0.2 (core UX + metadata)
- Milestone B: v0.3 + v0.4 (trust + actionable reports)
- Milestone C: v0.5 + v1.0 (quality + release)

## Execution Checklist (Issue Breakdown)

Use this section to create GitHub issues directly.

### Milestone A: v0.1 + v0.2

#### Issue A1: Add refresh workflow in list buffer
- Scope: add `trustrail-refresh`, wire `g` in mode map, preserve point when possible.
- Acceptance criteria: `g` rebuilds entries and redraws buffer without errors.
- Suggested labels: `feature`, `ux`, `good-first-issue`
- Effort: S

#### Issue A2: Add basic filtering by package name/summary
- Scope: interactive filter command, store active filter string, apply before rendering.
- Acceptance criteria: filter updates visible rows; clearing filter restores full list.
- Suggested labels: `feature`, `ux`
- Effort: M

#### Issue A3: Add row actions (`RET`, open dir, describe package)
- Scope: `RET` for describe/details, command to open package directory, add keybindings.
- Acceptance criteria: actions work on current row and handle missing metadata gracefully.
- Suggested labels: `feature`
- Effort: M

#### Issue A4: Add archive/maintainer/url metadata columns
- Scope: add `trustrail--package-archive`, `trustrail--package-maintainer`, `trustrail--package-url`; update table format and row vector.
- Acceptance criteria: columns render for archive and built-in packages with fallback values.
- Suggested labels: `feature`, `reporting`
- Effort: M

#### Issue A5: README update for keys, filters, and new columns
- Scope: document commands and keybindings added in A1-A4.
- Acceptance criteria: README usage section matches current mode behavior.
- Suggested labels: `docs`
- Effort: S

### Milestone B: v0.3 + v0.4

#### Issue B1: Add trust-status evaluator and column
- Scope: implement trust heuristics (`signed`, `unsigned`, `unknown`) with helper function.
- Acceptance criteria: each row shows a trust value; logic is documented in comments/docs.
- Suggested labels: `feature`, `security`
- Effort: M

#### Issue B2: Add risky-only filter and warning faces
- Scope: toggle filter for risky entries and apply faces to trust column.
- Acceptance criteria: toggle narrows rows correctly and visual state is obvious.
- Suggested labels: `feature`, `security`, `ux`
- Effort: M

#### Issue B3: Add export to Markdown and CSV
- Scope: export current visible table (respects active filter/sort) to chosen file.
- Acceptance criteria: generated files include headers and expected row count.
- Suggested labels: `feature`, `reporting`
- Effort: M

#### Issue B4: Add package details pane/buffer
- Scope: command to show full metadata for selected package (`extras`, source, dir).
- Acceptance criteria: details view opens from current row and handles missing values.
- Suggested labels: `feature`, `ux`
- Effort: M

### Milestone C: v0.5 + v1.0

#### Issue C1: Add ERT tests for accessors and row transform
- Scope: tests for `trustrail--package-*` helpers and `trustrail--tabulated-entry` shape.
- Acceptance criteria: tests pass locally and cover nil/fallback cases.
- Suggested labels: `test`
- Effort: M

#### Issue C2: Add CI for byte-compile and ERT
- Scope: GitHub Actions job for Emacs 27.1 and latest stable.
- Acceptance criteria: CI runs on push/PR and fails on compile/test failure.
- Suggested labels: `ci`, `quality`
- Effort: M

#### Issue C3: Release preparation docs
- Scope: add `CHANGELOG.md`, `CONTRIBUTING.md`, versioning/release checklist.
- Acceptance criteria: contributor and release steps are documented end-to-end.
- Suggested labels: `docs`, `release`
- Effort: S

#### Issue C4: v1.0 release cut
- Scope: final compatibility pass, version bump, tag, release notes.
- Acceptance criteria: tagged release with validated docs and stable behavior.
- Suggested labels: `release`
- Effort: S

## Implementation Notes

- Keep public API small (`trustrail-list-packages`, mode, export commands).
- Keep helpers private with `trustrail--` prefix.
- Favor pure transform helpers for easy ERT coverage.
- Prefer `pop-to-buffer` behavior for display compatibility.

