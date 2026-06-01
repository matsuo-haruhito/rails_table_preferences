# Rails Table Preferences

Rails Table Preferences is a Rails engine/gem for saving and restoring table display preferences in Rails applications.

It is designed for business applications with many index tables, where users need to customize visible columns, column order, column width, text truncation, filter UI state, sort UI state, presets, fixed columns, and export column order per table.

## Visual overview

The bundled editor and demo screen are intentionally lightweight, but they still cover the main moments users need to evaluate before wiring the gem into a real business screen.

![Representative demo screen showing the preset editor, scoped preset cues, and a pinned-column orders table.](docs/images/visual-overview-editor-and-table.svg)

- [Visual overview](docs/visual_overview.md): representative screen illustrations for the editor, shared/scoped preset orientation, export-preview-related cues, filter/sort state, and pinned-column table layout.
- [Demo screen generator](docs/demo.md): generate the lightweight verification screen shown in the screenshots.

## Documentation

Focused documentation is available under [`docs/`](docs/index.md). Start with the short integration path below, then use the docs index for the full catalog of focused guides.

- [Quick start](docs/quick_start.md): the shortest path from installation to a working table preference UI.
- [日本語 quick start](docs/quick_start_ja.md): a low-drift Japanese entry point for business-app integration; the English focused docs remain the detailed source of truth.
- [Production integration checklist](docs/production_integration_checklist.md): move from a working demo or quick start to a real host-app index screen.
- [Install path options](docs/install_paths.md): choose the smallest generator option set for default `stimulus-rails`, Vite/package entrypoint, skipped copied assets, or demo verification paths.
- [Support matrix](docs/support_matrix.md): Ruby/Rails runtime requirements, representative CI coverage, and host-app verification guidance for newer Rails releases.
- [Decision guide](docs/decision_guide.md): choose the right helper, adapter, or option for common use cases.
- [Demo screen generator](docs/demo.md): copy a lightweight browser verification screen into a host app.
- [Troubleshooting](docs/troubleshooting.md): common installation, Stimulus, CSS, API, filter/sort, scoped preset, and customization issues.

Core topic guides are grouped in the [docs index](docs/index.md), including resource tables, scoped presets, fixed columns, filter metadata, filter adapters, controller integration, export integration, accessibility, JavaScript entrypoints, mounted JSON API, manual QA, release checks, and package verification.

## Maintainer docs

- [Product Profile](Product%20Profile.md): concise maintainer-facing overview of the product surface, responsibility boundary, and release posture.
- [AGENTS.md](AGENTS.md): repository guardrails, source-of-truth order, and change boundaries for assisted maintenance work.
- [CHANGELOG.md](CHANGELOG.md): current unreleased scope and release narrative.

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

Rails Table Preferences targets Rails 7.0 and later. See the [Support matrix](docs/support_matrix.md) for the Ruby/Rails runtime requirements, representative CI coverage, and newer host-app verification guidance.

Current representative CI compatibility coverage is:

- Rails 7.0
- Rails 7.1
- Rails 7.2
- Rails 8.0

That list is the current representative CI coverage in this repository, not a blanket promise that every newer host-app Rails release is continuously exercised here.

If you are evaluating the gem in a newer host app release such as Rails 8.1, treat it as additional host-app verification work for now before assuming parity with the CI-covered matrix.

A compact verification path for those newer host-app Rails releases is:

- [Demo screen generator](docs/demo.md): check the bundled editor surface, scoped preset examples, current scope context summary, and export payload preview in a lightweight browser-facing screen.
- [Production integration checklist](docs/production_integration_checklist.md): bridge the working demo or quick start into a real host-app index screen, including owner, route, query params, authorization, layout, and export boundaries.
- [Sandbox Rails app verification](docs/sandbox.md): confirm install, engine mount, copied/package JavaScript and CSS, and end-to-end preference wiring in a minimal Rails app.
- [Manual QA checklist](docs/manual_qa.md): finish in the real host app to verify authentication, authorization, layout, accessibility, and existing search/export integration.

The development Gemfile currently tracks Rails 8.0.x.

Ruby 3.1+ is required.

GitHub Actions keeps the default RSpec / JavaScript syntax / gem build / package verification job on both pushes and pull requests. Pull requests also run representative Rails compatibility lanes for Rails 7.0, Rails 7.1, Rails 7.2, and Rails 8.0 so lower-bound and current-baseline regressions are easier to spot before merge.

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
