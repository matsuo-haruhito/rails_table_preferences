# Rails Table Preferences

Rails Table Preferences is a Rails engine/gem for saving and restoring table display preferences in Rails applications.

It is designed for business applications with many index tables, where users need to customize visible columns, column order, column width, text truncation, filter UI state, sort UI state, presets, fixed columns, and export column order per table.

## Documentation

Focused documentation is available under [`docs/`](docs/index.md):

- [Quick start](docs/quick_start.md): the shortest path from installation to a working table preference UI.
- [Resource table adapters](docs/resource_tables.md): infer user-facing columns from Active Record metadata, apply profile overrides, and optionally connect TreeView or Rails Fields Kit.
- [Decision guide](docs/decision_guide.md): choose the right helper, adapter, or option for common use cases.
- [Scoped presets](docs/scoped_presets.md): owner, shared, role, and organization scoped presets, default resolution, and minimal host-app operating patterns.
- [Fixed columns and column groups](docs/fixed_columns_and_groups.md): `fixed:` / `pinned:` columns, sticky CSS hooks, and `group:` metadata.
- [Export integration](docs/export_integration.md): reuse saved column visibility, order, labels, and metadata for CSV, Excel, or report exports.
- [Accessibility baseline](docs/accessibility.md): accessibility hooks provided by the bundled editor/controller and host app responsibilities.
- [Demo screen generator](docs/demo.md): `--with-demo` generator option for copying a lightweight browser verification screen into a host app.
- [Sandbox Rails app verification](docs/sandbox.md): minimal Rails app setup for end-to-end verification before real app integration.
- [Manual QA checklist](docs/manual_qa.md): browser and host application checks to run before asking real users to try the feature.
- [Release checklist](docs/release_checklist.md): packaging, generator, CI, documentation, and sandbox checks before tagging or publishing a release.
- [Package verification](docs/package_verification.md): build and inspect the gem package before tagging or publishing a release.
- [Practical examples](docs/examples.md): realistic list-screen integrations for existing `search(params)` / `order_by(params[:sort])` controllers and Ransack controllers.
- [Troubleshooting](docs/troubleshooting.md): common installation, Stimulus, CSS, API, filter/sort, scoped preset, and customization issues.
- [Controller integration](docs/controller_integration.md): resolving saved preferences and passing filter/sort/export params to existing Rails controllers.
- [Filter metadata](docs/filter_metadata.md): declaring filterable/sortable columns and understanding neutral filter/sort settings.
- [Filter adapters](docs/filter_adapters.md): adapter strategy for Ransack, Datagrid, Filterrific, and host application search objects.
- [JavaScript entrypoints](docs/javascript_entrypoints.md): Stimulus registration paths for default `stimulus-rails`, Vite, `app/frontend`, and custom JS bundlers.
- [JavaScript controller notes](docs/javascript_controller.md): bundled Stimulus controller responsibilities and safety boundaries.

## Goals

- Save table display preferences per owner model, usually a user.
- Support column visibility, order, width, truncation, fixed/pinned metadata, and column group metadata.
- Support multiple named presets, default presets, shared presets, role defaults, and organization defaults.
- Support saved filter and sort UI state without becoming a query builder.
- Provide Rails helpers, controller helpers, a small JSON API, and a bundled Stimulus controller.
- Keep compatibility with existing `ColumnAdjustment`-style implementations.
- Allow host applications to customize ERB, CSS, JavaScript, and column-label resolution.
- Integrate with existing controller params, Ransack, host application search objects, and export code.

## Supported versions

Rails Table Preferences targets Rails 7.0 and later.

Primary support is planned for:

- Rails 7.1
- Rails 7.2
- Rails 8.0
- Rails 8.1

Rails 7.0 is expected to work, but Rails 7.1+ is recommended.

Ruby 3.1+ is required.

## Installation

Rails Table Preferences stores table preferences in the host application's primary database using a normal Rails migration.

```bash
bin/rails generate rails_table_preferences:install
bin/rails db:migrate
```

The generator creates:

- `config/initializers/rails_table_preferences.rb`
- `db/migrate/*_create_table_preferences.rb`
- `app/javascript/controllers/rails_table_preferences_controller.js`
- `app/assets/stylesheets/rails_table_preferences.css`

Mount the engine when using the bundled JSON API:

```ruby
# config/routes.rb
mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
```

For Vite / `app/frontend/entrypoints/application.js`, register the packaged Stimulus controller explicitly:

```js
import { Application } from "@hotwired/stimulus"
import RailsTablePreferencesController from "rails_table_preferences/controller"

const application = Application.start()
application.register("rails-table-preferences", RailsTablePreferencesController)
```

If the host app already starts Stimulus elsewhere, reuse that existing `application` and only add `application.register(...)` here. Do not call `Application.start()` a second time from the same host app.

The package root also exposes a named export:

```js
import { RailsTablePreferencesController } from "rails_table_preferences"
```

When using Vite or another JS bundler, make sure the host app can resolve the gem's packaged `app/javascript/rails_table_preferences/*` files. A minimal Vite alias looks like this:

```ts
import { execSync } from "node:child_process"
import { fileURLToPath } from "node:url"

function gemPath(name: string) {
  return execSync(`bundle show ${name}`, { encoding: "utf-8" }).trim()
}

function gemJavaScriptPath(name: string, entrypoint: string) {
  return fileURLToPath(new URL(`app/javascript/${entrypoint}`, `file://${gemPath(name)}/`))
}

resolve: {
  alias: [
    { find: /^rails_table_preferences$/, replacement: gemJavaScriptPath("rails_table_preferences", "rails_table_preferences/index.js") },
    { find: /^rails_table_preferences\/controller$/, replacement: gemJavaScriptPath("rails_table_preferences", "rails_table_preferences/controller.js") }
  ]
}
```

See [JavaScript entrypoints](docs/javascript_entrypoints.md) for the default `stimulus-rails`, Vite, and custom bundler registration paths.

For a lightweight local browser verification screen, add `--with-demo`:

```bash
bin/rails generate rails_table_preferences:install --with-demo
```

Then add a route for the copied demo screen:

```ruby
# config/routes.rb
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

See [Demo screen generator](docs/demo.md) and [Sandbox Rails app verification](docs/sandbox.md) for the full local verification flow.

If preferences should belong to a model other than `User`, pass an owner model. The value can be singular or plural:

```bash
bin/rails generate rails_table_preferences:install --owner-model customers
bin/rails generate rails_table_preferences:install --owner-model client
```

`customers` generates `Customer` / `customer_id`; `client` generates `Client` / `client_id`. Override the generated foreign key only when needed:

```bash
bin/rails generate rails_table_preferences:install --owner-model customers --owner-foreign-key member_id
```

Skip copied assets when the host app wants to provide its own implementation:

```bash
bin/rails generate rails_table_preferences:install --skip-javascript
bin/rails generate rails_table_preferences:install --skip-stylesheets
```

You can also copy only the JavaScript controller or stylesheet later:

```bash
bin/rails generate rails_table_preferences:javascript
bin/rails generate rails_table_preferences:stylesheets
```

## Current scope

The current implementation includes the former v0.2 roadmap items in the initial v0.1 release target.

Included in v0.1 scope:

- Table-specific display settings
- Owner-specific preference persistence
- Shared presets
- Role and organization scoped presets/defaults
- Column visibility
- Column order
- Column width
- Text truncation metadata
- Fixed/pinned column metadata and CSS/JS hooks
- Column group metadata and grouping helper
- Multiple presets and default presets
- Ignored columns
- Configurable column labels through explicit labels, explicit i18n keys, database column comments, and optional locale/humanize fallbacks
- Filter metadata and filter panel UI foundation
- Sort metadata and sortable header click UI
- Controller params and Ransack adapters
- Controller/view helpers for existing search forms
- Export payload helper for CSV, Excel, and report generation in the host app
- Baseline accessibility hooks for generated controls
- Rails engine structure
- View helpers
- Controller helpers
- Stimulus controller
- Package JavaScript entrypoints for Vite and other JS bundlers
- Install, JavaScript, stylesheet, view, and demo generators
- Migration generator
- Compatibility path for existing JSON column-adjustment values
- Local demo and sandbox verification guidance
- Manual QA, troubleshooting, decision guide, scoped preset, fixed column, export, accessibility, release checklist, and package verification documentation

## Out of scope

Rails Table Preferences intentionally does not try to become:

- A generic ActiveRecord query builder
- A Ransack replacement
- A Datagrid replacement
- A Filterrific replacement
- A DataTables replacement
- An authorization system
- An automatic association/join inference system
- A pagination abstraction
- A CSV/Excel file generator
- A React or Vue component library
- A complete admin UI for managing shared, role, or organization presets

## Roadmap

### v0.1: Initial usable release

This is the current target version. It is intended to be usable in real Rails applications after local sandbox/manual verification.

Included scope:

- Column visibility, order, width, truncation, fixed/pinned metadata, overflow metadata, and column group metadata
- Spreadsheet-like auto-fit by double-clicking a column resize handle
- Owner, shared, role, and organization scoped presets
- Default preset resolution across owner, role, organization, and shared scopes
- Apply, Save, Save as new, Delete, and Reset actions
- Read-only handling for non-owner presets in the normal editor path
- Ignored columns
- Configurable column labels through explicit labels, explicit i18n keys, database column comments, and optional locale/humanize fallbacks
- Filter metadata and saved filter UI state
- Sort metadata and sortable header click UI
- Plain controller params adapter
- Ransack adapter
- Hidden fields helper for existing search forms
- Export payload helper for host app CSV/Excel/report code
- Rails helpers and Stimulus integration
- JavaScript package entrypoints for Vite / `app/frontend` registration
- JSON API for preference and preset persistence
- Migration, install, JavaScript, stylesheet, view, and demo generators
- `--with-demo`, `--skip-javascript`, and `--skip-stylesheets` install options
- Owner model and owner foreign key generator/configuration options
- Existing `ColumnAdjustment` compatibility and import guidance
- Copy-based ERB, CSS, and JavaScript customization path
- Quick start, practical examples, troubleshooting, demo, sandbox, decision guide, scoped presets, fixed columns/groups, export integration, accessibility baseline, manual QA, release checklist, and package verification docs

Remaining before tagging v0.1:

- Confirm CI is green on the release commit
- Do one final sandbox/demo verification pass
- Inspect package contents with [Package verification](docs/package_verification.md)
- Move `CHANGELOG.md` entries from `[Unreleased]` to `0.1.0` when tagging
- Review README/docs consistency against the released behavior

### Later candidates

These are possible future directions, not committed release promises:

- More adapter examples for Datagrid, Filterrific, or host application search objects