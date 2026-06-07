# Package verification

Use this guide after `bundle exec rake build` to confirm the gem package contains the files a host Rails application needs.

## Build

```bash
bundle exec rake build
```

This should create a `.gem` file under `pkg/`.

## Automated verification

Run the package verification task:

```bash
bundle exec rake package:verify
```

The task checks the newest built gem under `pkg/` and fails if required runtime, generator, asset, task, changelog, package metadata, JavaScript entrypoint, packaged declaration, resource table partial, or documentation files are missing. It also reads the packaged `package.json`, verifies that documented `exports` targets point at files that are present in the same built gem, checks that those JavaScript export targets' relative import/export references resolve to packaged `.js` files, checks that declaration targets' relative import/export references resolve to packaged `.d.ts` files, and verifies that the packaged `package.json` remains private resolver metadata (`private: true`, `version: "0.0.0"`).

A successful run prints a message like:

```text
Package verification passed: rails_table_preferences-0.1.0.alpha.gem
```

If required files, package export targets, package-internal JavaScript imports, package-internal declaration imports, or packaged metadata are missing or invalid, the task prints the missing paths and exits with failure.

Failure output starts with a compact summary line before the detailed lists:

```text
Package verification failed: rails_table_preferences-0.1.0.alpha.gem
Package verification summary: 4 issue(s) (required files: 1, package export targets: 1, package internal JavaScript imports: 1, package internal declaration imports: 1, package metadata errors: 0)
```

Use the summary line in PR bodies, the pull request template's release/package evidence field, release checklist notes, or CI triage comments when you need to share the failure quickly. Then use the detailed lists below it to find the exact missing file, export target, unresolved JavaScript import, unresolved declaration import, or package metadata error. The summary is a human-readable wrapper around the existing verifier result; it does not replace the structured `PackageVerifier.call` hash.

## Manual inspection

The automated task is the normal gate. Manual inspection is still useful before tagging a release.

List the packaged files:

```bash
gem contents pkg/rails_table_preferences-*.gem --all
```

Or unpack the gem into a temporary directory:

```bash
rm -rf tmp/package_check
mkdir -p tmp/package_check
gem unpack pkg/rails_table_preferences-*.gem --target tmp/package_check
find tmp/package_check -maxdepth 4 -type f | sort
```

## Required files

The verification task checks that the package includes at least:

```text
app/assets/stylesheets/rails_table_preferences.css
app/controllers/rails_table_preferences/application_controller.rb
app/controllers/rails_table_preferences/preferences_controller.rb
app/controllers/concerns/rails_table_preferences/controller.rb
app/helpers/rails_table_preferences/table_preferences_helper.rb
app/helpers/rails_table_preferences/table_preferences_editor_html_options_helper.rb
app/helpers/rails_table_preferences/column_options_helper.rb
app/javascript/controllers/rails_table_preferences_controller.js
app/javascript/rails_table_preferences/controller.js
app/javascript/rails_table_preferences/controller.d.ts
app/javascript/rails_table_preferences/index.js
app/javascript/rails_table_preferences/index.d.ts
app/views/rails_table_preferences/_editor.html.erb
app/views/rails_table_preferences/_resource_table.html.erb
app/views/rails_table_preferences/_tree_resource_table.html.erb
app/views/rails_table_preferences/_tree_resource_table_row.html.erb
config/routes.rb
lib/generators/rails_table_preferences/install/install_generator.rb
lib/generators/rails_table_preferences/install/templates/create_table_preferences.rb
lib/generators/rails_table_preferences/install/templates/initializer.rb
lib/generators/rails_table_preferences/install/templates/demo/orders_controller.rb
lib/generators/rails_table_preferences/install/templates/demo/index.html.erb
lib/generators/rails_table_preferences/javascript/javascript_generator.rb
lib/generators/rails_table_preferences/stylesheets/stylesheets_generator.rb
lib/generators/rails_table_preferences/views/views_generator.rb
lib/tasks/rails_table_preferences.rake
lib/rails_table_preferences.rb
lib/rails_table_preferences/adapters/active_record_columns.rb
lib/rails_table_preferences/adapters/column_like.rb
lib/rails_table_preferences/adapters/controller_params.rb
lib/rails_table_preferences/adapters/ransack.rb
lib/rails_table_preferences/column_definition.rb
lib/rails_table_preferences/configuration.rb
lib/rails_table_preferences/export_payload.rb
lib/rails_table_preferences/package_verifier.rb
lib/rails_table_preferences/renderer_registry.rb
lib/rails_table_preferences/settings_normalizer.rb
lib/rails_table_preferences/table_profile.rb
lib/rails_table_preferences/table_state.rb
lib/rails_table_preferences/value_resolver.rb
package.json
README.md
CHANGELOG.md
LICENSE
docs/index.md
docs/quick_start.md
docs/quick_start_ja.md
docs/install_paths.md
docs/resource_tables.md
docs/resource_table_cell_hooks.md
docs/table_data_attributes.md
docs/resource_table_formatter_contract.md
docs/virtual_columns_query_boundary.md
docs/decision_guide.md
docs/scoped_presets.md
docs/preset_selector_scope_labels.md
docs/fixed_columns_and_groups.md
docs/column_overflow.md
docs/resize_auto_fit.md
docs/export_integration.md
docs/accessibility.md
docs/editor_i18n.md
docs/editor_entrypoint_affordances.md
docs/editor_root_options.md
docs/helper_free_controller_root_urls.md
docs/non_goals.md
docs/visual_overview.md
docs/images/visual-overview-editor-and-table.svg
docs/images/visual-overview-filter-and-pinned-columns.svg
docs/demo.md
docs/sandbox.md
docs/examples.md
docs/troubleshooting.md
docs/manual_qa.md
docs/release_checklist.md
docs/package_verification.md
docs/support_matrix.md
docs/controller_integration.md
docs/json_api.md
docs/filter_metadata.md
docs/filter_adapters.md
docs/select_filter_troubleshooting.md
docs/javascript_entrypoints.md
docs/javascript_controller.md
```

Keep this list synchronized with `RailsTablePreferences::PackageVerifier::REQUIRED_PATHS`. The runtime entries are representative helper, adapter, registry, formatter, and resource table files rather than a complete freeze of every file under `lib/`. The JavaScript entrypoint entries include the packaged `.d.ts` files because TypeScript host apps use them to resolve the public package imports. The resource table partial entries guard the default `resource_table_for` and `tree_resource_table_for` rendering paths that a host app uses without custom partial configuration. The documentation entries are package entrances from the README and docs index rather than a complete freeze of every file under `docs/`.

## Required path selection criteria

Add a file to `REQUIRED_PATHS` when its absence would make the packaged gem unusable or make a documented public entry point fail after installation. The list is intentionally representative: it protects the most important install, runtime, customization, and documentation surfaces without turning package verification into a full inventory of the repository.

Use these criteria when adding or reviewing required paths:

- Runtime entrypoints that host apps call directly, such as public helpers, controllers, adapters, registry files, resource table partials, rake tasks, and copied generator templates.
- JavaScript package entrypoints, their minimal TypeScript declaration files, and any file named by `package.json` `exports`. The export-target check also verifies these paths from packaged metadata and follows their static relative import/export references to packaged JavaScript and declaration files.
- Package metadata and release-facing files that should always ship, including `package.json`, `README.md`, `CHANGELOG.md`, `LICENSE`, and this verification guide.
- Focused docs that are directly linked from README or the docs index as user-facing setup, integration, customization, troubleshooting, support, release, or QA entry points. Current required focused docs include resource table cell hooks, table data attributes, resize auto-fit, editor entrypoint affordances, preset selector scope labels, virtual column query boundary, editor root options, helper-free controller root URL guide, select filter troubleshooting, and the JavaScript entrypoint/controller guides because they are primary docs-index entrances for shipped behavior.
- Scope-boundary docs that keep the packaged release from being mistaken for a broader product surface. `docs/non_goals.md` is required for that reason: it records intentionally deferred query builder, export generation, admin UI, heavy browser test, and complex sticky layout directions that are linked from the docs index and should ship with the release package.
- Visual or other static assets that a required doc directly references, such as the visual overview SVGs.

Do not add every repository file just because it exists. In particular, avoid requiring all docs, all examples, temporary/generated intermediate files, test files, mockups, or future proposal notes unless they are promoted to a packaged public entry point. A docs page that is only linked from a nearby guide can stay outside `REQUIRED_PATHS` when the package remains usable without treating that page as a primary entrance. For a new docs guide, first decide whether README or `docs/index.md` should make it a primary package entrance; if not, leave the fixed list unchanged and document the narrower link from the nearby guide instead.

When a new public helper, partial, package export, packaged declaration, README-linked guide, docs-index primary guide, or required visual asset is added, update `RailsTablePreferences::PackageVerifier::REQUIRED_PATHS`, the package verifier spec, and this guide together. If the choice is unclear, leave the fixed list unchanged and document the follow-up question in the relevant Issue or PR instead of broadening the guardrail by default.

## Package export targets

The package verification task reads the packaged `package.json` and confirms every string target under `exports` is included in the built gem. For the current package metadata, that means:

```text
. types -> app/javascript/rails_table_preferences/index.d.ts
. default -> app/javascript/rails_table_preferences/index.js
./controller types -> app/javascript/rails_table_preferences/controller.d.ts
./controller default -> app/javascript/rails_table_preferences/controller.js
```

After confirming those export target files exist, the verifier scans JavaScript export targets' static relative `import ... from`, side-effect `import`, and `export ... from` references. Extensionless references such as `./controller` and `../controllers/rails_table_preferences_controller` must resolve to packaged JavaScript files, so package verification catches drift where an exported entrypoint ships but one of its internal package files does not.

The verifier performs the same lightweight relative-target check for packaged declaration export targets. For example, `app/javascript/rails_table_preferences/index.d.ts` re-exports `./controller`, and package verification now expects that reference to resolve to `app/javascript/rails_table_preferences/controller.d.ts` inside the same built gem. This keeps TypeScript host-app import metadata aligned without adding a full TypeScript compiler check.

This check complements the fixed required-file list: the fixed list catches accidental removal of representative entrypoint files and declarations, while the export target and internal import checks catch drift between `package.json`, JavaScript entrypoint wiring, declaration re-exports, and the gem contents. It is intentionally a lightweight package-content guard, not a replacement for the manual host-app Vite check in `docs/release_checklist.md`.

The packaged `package.json` is resolver metadata for these gem-packaged JavaScript entrypoints. Its current `private: true` and `version: "0.0.0"` values are intentional metadata boundaries: they do not make the gem a separate npm distribution. The verifier treats drift from `private: true` or `version: "0.0.0"` as a package metadata error so release/package evidence keeps npm distribution policy separate from the Ruby gem package. It still does not treat the JavaScript version as something that must track `RailsTablePreferences::VERSION`. If the project later chooses an npm distribution strategy, document and test that as a separate release policy change.

## Runtime import smoke boundary

`bundle exec rake package:verify` confirms that package metadata, files, JavaScript relative imports, and TypeScript declaration re-exports are internally consistent in the built gem. It does not run a host-app bundler or install frontend dependencies. Keep the real `rails_table_preferences` and `rails_table_preferences/controller` ESM import smoke as release or host-app evidence in the Vite / `app/frontend` checklist rather than adding a partial CI import that could pass without proving real bundler integration.

## Why this matters

The test suite can pass even if package contents are incomplete. Missing generator templates, copied JavaScript, copied CSS, package entrypoints, packaged declarations, package metadata, rake tasks, changelog, visual overview assets, README-linked docs, or resource table runtime files usually appear only when the gem is installed into a host Rails app.

## Current CI gate

CI runs:

```bash
bundle exec rspec
node --check app/javascript/controllers/rails_table_preferences_controller.js
node --check app/javascript/rails_table_preferences/controller.js
node --check app/javascript/rails_table_preferences/index.js
bundle exec rake build
bundle exec rake package:verify
```

The JavaScript syntax step checks the copied controller, the package controller entrypoint, and the package root entrypoint. Keep this snippet synchronized with `.github/workflows/ci.yml`; `docs/release_checklist.md` lists the same local release-prep commands.

The package verification task also follows the documented package root and controller export targets and checks their packaged internal relative JavaScript and declaration references. That complements the syntax check by guarding package export wiring against missing files in the built gem while leaving full host-app bundler behavior to the release checklist's manual Vite integration check.

Manual package inspection is still recommended before tagging a release.
