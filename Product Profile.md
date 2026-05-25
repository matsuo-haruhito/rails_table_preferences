# Product Profile

## Product summary

Rails Table Preferences is a Rails engine/gem for server-rendered Rails applications that need reusable table display preferences.

It helps host applications save and restore:

- visible columns
- column order and width
- truncation / overflow settings
- fixed or pinned column metadata
- column group metadata
- filter and sort UI state
- owner, shared, role, and organization scoped presets
- export column payloads for host-app CSV, Excel, or report generation

The gem is designed for business applications with many list screens where users need to tune table presentation without turning the gem into a full admin framework or query builder.

## Intended users

Primary users are maintainers integrating the gem into an existing Rails application.

Typical readers are:

- Rails developers wiring the gem into server-rendered index screens
- maintainers deciding whether to use helper-first or adapter-first integration
- maintainers validating demo, sandbox, and release flows before publishing
- host application teams customizing copied ERB, CSS, or Stimulus code

## What the gem owns

Rails Table Preferences owns:

- the table preference editor UI
- saved column visibility, order, width, truncation, and pinned metadata
- column group metadata helpers
- preset persistence and default resolution across owner / role / organization / shared scopes
- filter and sort UI state plus adapter params
- resource table column inference and profile overrides when the helper path is used
- ordered export payload metadata
- bundled accessibility baseline for generated controls
- generators for install, JavaScript, stylesheets, views, and demo setup

## What the host application owns

The host application still owns:

- actual database query execution
- joins, association logic, and authorization
- semantic page structure around the generated controls
- final sticky-column offset and scroll-container polish for complex layouts
- grouped table header markup
- CSV, Excel, or report file generation
- complex admin UI for shared, role, or organization presets
- final styling and product-specific UX choices

## Current stage

The repository is in active early release work for `0.1.0`.

Current repository signals:

- the README and docs describe the feature set as ready for sandbox/manual verification in real Rails apps
- `CHANGELOG.md` still keeps `0.1.0` under an unreleased target
- release guidance expects CI, package verification, and one sandbox/demo verification pass before tagging

## Core value

This gem exists to make existing Rails list screens more configurable without forcing a host application to adopt a new table framework.

The preferred shape is:

1. keep the host app's controller, query, and authorization logic
2. add structured column metadata and a reusable preference editor
3. persist table display choices and optional preset scopes
4. reuse the same saved settings for filter/sort UI state and export payload ordering

## Non-goals

This repository intentionally does not aim to become:

- a generic query builder
- a replacement for Ransack, Datagrid, or Filterrific
- a CSV/Excel file generator
- a full admin framework for shared preset management
- a heavy browser-test-first UI product
- a complex sticky layout engine

See [`docs/non_goals.md`](docs/non_goals.md) for the durable wording.

## Main documentation map

Start with:

- [`README.md`](README.md): public overview, installation, scope, and API direction
- [`docs/index.md`](docs/index.md): focused documentation map and recommended integration order
- [`docs/quick_start.md`](docs/quick_start.md): shortest path to a working integration
- [`docs/decision_guide.md`](docs/decision_guide.md): choose the right helper or adapter for a use case

Then use focused docs such as:

- [`docs/scoped_presets.md`](docs/scoped_presets.md)
- [`docs/fixed_columns_and_groups.md`](docs/fixed_columns_and_groups.md)
- [`docs/export_integration.md`](docs/export_integration.md)
- [`docs/controller_integration.md`](docs/controller_integration.md)
- [`docs/javascript_entrypoints.md`](docs/javascript_entrypoints.md)
- [`docs/accessibility.md`](docs/accessibility.md)
- [`docs/demo.md`](docs/demo.md)
- [`docs/manual_qa.md`](docs/manual_qa.md)
- [`docs/release_checklist.md`](docs/release_checklist.md)

## Maintenance cues

When repository docs are updated, keep these relationships aligned:

- public overview in `README.md`
- docs index and integration order in `docs/index.md`
- durable product framing in `Product Profile.md`
- maintainer workflow notes in `AGENTS.md`
- feature-specific contracts in the relevant `docs/*.md` files

If code and docs disagree, prefer the current code and the focused docs closest to the feature before expanding high-level summaries.
