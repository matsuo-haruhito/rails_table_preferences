# Changelog

All notable changes to Rails Table Preferences will be documented in this file.

The format is based on a lightweight Keep a Changelog style, and this project currently follows early pre-1.0 semantic versioning.

## [Unreleased]

### Added

- Initial table preference persistence model and Rails engine structure.
- Owner-specific table preference records with configurable owner model and owner foreign key.
- Scoped preset support for owner, shared, role, and organization presets.
- Default preset resolution across owner, role, organization, and shared scopes.
- JSON API for listing, loading, creating, updating, and deleting presets.
- Rails controller helpers for resolving saved settings and converting saved filter/sort state into host app params.
- Plain controller params adapter for existing `search(params)` / `order_by(params[:sort])` style controllers.
- Ransack params adapter.
- Hidden fields helper for submitting saved filter/sort params through existing search forms.
- Export payload helper for host app CSV, Excel, or report generation.
- Column definition helper with labels, locale lookup, visibility, order, width, truncation, filters, sorting, fixed/pinned metadata, groups, and ignored columns.
- Resource table helpers for convention-first Active Record column inference, table profile overrides, optional tree table rendering, and additive table semantics.
- Resource table helpers can pass table HTML options such as `id`, `class`, `data`, and `aria` through to the rendered table while preserving gem-owned controller data attributes.
- Resource table helpers support opt-in captions through `caption:` and keep the caption contract separate from table HTML options.
- Resource table helpers support `render_editor: false` so host apps can render the generated editor separately while keeping the default editor-plus-table behavior unchanged.
- Table profiles can add virtual or computed columns, including formatter-backed values that are not inferred from the Active Record model.
- Renderer registries for mapping filter and editor metadata to host-app helper libraries such as Rails Fields Kit.
- Column group helper for host app grouped table headers and grouped export headers.
- Settings normalizer for current and legacy `ColumnAdjustment`-style settings payloads.
- Bundled Stimulus controller for applying column visibility, order, width, truncation, filters, sorts, header drag reorder, resize handles, pinned column hooks, and preset editing behavior.
- Copy-based JavaScript, stylesheet, view, and install generators.
- Optional `--with-demo` and `--with-demo-route` install generator modes for local browser verification.
- Generated demo verification includes owner, role, organization, export payload, fixed/grouped column, async failure recovery, and demo-state reset checks.
- Optional `--skip-javascript` and `--skip-stylesheets` install generator modes.
- Legacy `ColumnAdjustment` import rake task.
- Documentation for quick start, resource table adapters, decision guide, practical examples, controller integration, filter metadata, filter adapters, scoped presets, fixed columns/groups, column overflow metadata, export integration, accessibility baseline, bundled editor i18n keys, visual overview, non-goals, demo, sandbox verification, troubleshooting, manual QA, release checklist, package verification, JavaScript entrypoints, JavaScript controller notes, and Turbo reconnect checks.
- Documentation for the resource table formatter contract, including formatter arity, nil-return behavior, and host-app formatting responsibility.
- Maintainer-facing `Product Profile.md` and repository `AGENTS.md` guides.
- GitHub Actions CI for Ruby specs, JavaScript syntax, gem build, and package verification, plus representative pull-request Rails compatibility lanes for Rails 7.0, 7.1, 7.2, and 8.0.
- Package verification now guards representative core runtime files used by resource tables, adapters, formatters, registries, and helpers.

### Changed

- The initial release target now includes the former v0.2 advanced preference distribution and table layout features.
- README roadmap and current scope were updated to reflect the expanded v0.1 scope.
- Generated migrations use nullable owner references and `scope_type` / `scope_key` to support owner, shared, role, and organization presets.
- The bundled JavaScript controller treats non-owner presets as read-only in the normal editor path and falls back to creating an owner preset when saving edits.
- The Ransack adapter can read normalized column metadata so `filter: { param: ... }` and `sort_param:` override the saved column key before params are handed to the host app.
- The default development Gemfile now pins Rails 8.0.x to match the current representative pull-request compatibility matrix.
- The package and JavaScript verification path now smoke-loads the documented package root and controller entrypoints in a minimal Node sandbox.
- Documentation now states the bundled sort UI single-sort boundary and leaves multi-sort composition to host apps.

### Fixed

- Generator task loading works when the gem is used from a host Rails app.
- Generated migration index names avoid database identifier length issues.
- Engine route names avoid duplicate route name conflicts in the test app.
- Private `current_user` methods are supported.
- Saved filter/sort state survives editor apply operations.
- Current column metadata overrides stale saved metadata for labels, filters, sortable state, and pinned state.
- Ignored columns are filtered out of editor payloads and saved settings.

## [0.1.0] - Unreleased

Initial public release target. The entries above describe the planned contents of this release until it is tagged.