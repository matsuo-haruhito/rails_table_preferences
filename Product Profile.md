# Product Profile

## Summary

Rails Table Preferences is a Rails engine/gem for business-style Rails applications with dense index tables. It lets a host application save and restore table display preferences such as visible columns, column order, column width, overflow behavior, fixed columns, column groups, filter UI state, sort UI state, and named presets.

The gem is intentionally integration-friendly rather than all-encompassing. It helps a host application carry display preferences through existing tables, search forms, controller params, convention-first resource table helpers, and export flows without taking over the application's business queries or administrative workflows.

## Intended users

Primary users are maintainers of Rails applications who need configurable table UX for operators, back-office teams, or other users working with large list screens.

Typical adopters need:

- owner-specific display preferences
- optional shared, role, or organization scoped presets
- compatibility with existing search and sort flows
- convention-first table rendering from Active Record metadata with small profile overrides
- copyable customization paths for ERB, CSS, JavaScript, and locales

## Core capabilities

Current repository scope includes:

- table column definitions with labels, visibility, order, width, overflow/truncation, fixed/pinned metadata, groups, filters, sorts, and ignored columns
- resource table helpers that infer Active Record columns, apply table profile overrides, expose stable body-cell metadata hooks, and optionally connect TreeView-style tree tables
- table data attribute merge rules that let host apps add their own controllers while preserving gem-owned table preference bindings
- renderer registries that let host apps map filter/editor metadata to helper libraries such as Rails Fields Kit without making this gem depend on those libraries
- editor and table helpers for rendering a configurable table-preference UI, including root HTML option pass-through for host-app placement attributes
- owner/shared/role/organization preset persistence and default resolution
- controller helpers for merging saved filter/sort state into host-app params
- export payload helpers for CSV/Excel/report code implemented by the host app
- a bundled Stimulus controller and lightweight JSON API
- install/demo/customization generators and focused operational documentation

## Responsibility boundary

Rails Table Preferences owns:

- table display preference persistence and editing
- saved filter/sort UI state as UI metadata
- column/preset metadata and helper/controller integration
- Active Record column inference, table profile override application, and renderer registry lookup for resource table helpers
- body-cell data attributes, editor root HTML option merging, and table preference data-attribute protection for generated helper surfaces
- baseline accessibility hooks and lightweight demo/sandbox guidance

Host applications own:

- actual search/query execution
- authorization and tenant/business rules
- grouped header markup and advanced scroll/sticky layout polish
- CSS and manual QA for dense headers, horizontal scroll containers, and resize/auto-fit usability in the final screen
- CSV, Excel, or report file generation
- resource table partial layout, route URLs, and behavior behind rendered filter/editor controls
- full administrative management UI for non-owner presets
- final application design and workflow-specific UX

## Integration posture

The project favors practical Rails integration over framework lock-in.

Maintainers should expect to combine the gem with:

- existing `search(params)` / `order_by(params[:sort])` flows
- Ransack or other search adapters when needed
- `resource_table_for` / `tree_resource_table_for` when convention-first Active Record column inference is useful
- table profiles and renderer registrations when a screen needs small column, filter, editor, or display overrides
- host-app export code driven by `rails_table_preference_export_payload`
- host-app customization via copied ERB, CSS, JavaScript, and locale files

## Release posture

The README currently positions the gem as active initial development targeting an initial `0.1.x` release line.

Current representative pull-request compatibility coverage is Rails 7.0, Rails 7.1, Rails 7.2, and Rails 8.0, while the development Gemfile tracks Rails 8.0.x. Host applications evaluating newer Rails releases should treat that as additional verification space until the representative compatibility matrix expands.

Repository-level release confidence is expected to come from:

- `bundle exec rspec`
- `node --check app/javascript/controllers/rails_table_preferences_controller.js`
- `bundle exec rake build`
- `bundle exec rake package:verify`
- representative pull-request compatibility lanes for Rails 7.0 / 7.1 / 7.2 / 8.0
- sandbox/demo verification
- manual QA and package verification docs

## Non-goals

The project does not aim to become:

- a generic Active Record query builder
- a replacement for Ransack, Datagrid, or Filterrific
- an authorization framework
- a CSV/Excel/report generator
- a complete admin UI framework for shared/role/organization preset management
- a React/Vue component library

## Maintainer references

Start with these files when orienting yourself. Treat `docs/index.md` as the source of truth for the full focused-docs catalog; this list only highlights the entries most useful for onboarding, release readiness, and operational QA.

- `README.md`
- `docs/index.md`
- `docs/quick_start.md`
- `docs/install_paths.md`
- `docs/support_matrix.md`
- `docs/decision_guide.md`
- `docs/resource_tables.md`
- `docs/resource_table_cell_hooks.md`
- `docs/table_data_attributes.md`
- `docs/resource_table_formatter_contract.md`
- `docs/editor_root_options.md`
- `docs/resize_auto_fit.md`
- `docs/json_api.md`
- `docs/manual_qa.md`
- `docs/release_checklist.md`
- `docs/package_verification.md`
- `docs/troubleshooting.md`
- `AGENTS.md`
- `CHANGELOG.md`
