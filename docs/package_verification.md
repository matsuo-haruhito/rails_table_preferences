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

The task checks the newest built gem under `pkg/` and fails if required runtime, generator, asset, task, changelog, package metadata, JavaScript entrypoint, resource table partial, or documentation files are missing. It also reads the packaged `package.json` and verifies that documented `exports` targets point at files that are present in the same built gem.

A successful run prints a message like:

```text
Package verification passed: rails_table_preferences-0.1.0.alpha.gem
```

If required files or package export targets are missing, the task prints the missing paths and exits with failure. Invalid packaged `package.json` metadata is reported as a package metadata error.

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
app/helpers/rails_table_preferences/column_options_helper.rb
app/javascript/controllers/rails_table_preferences_controller.js
app/javascript/rails_table_preferences/controller.js
app/javascript/rails_table_preferences/index.js
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
docs/resource_tables.md
docs/resource_table_formatter_contract.md
docs/decision_guide.md
docs/scoped_presets.md
docs/fixed_columns_and_groups.md
docs/column_overflow.md
docs/export_integration.md
docs/accessibility.md
docs/editor_i18n.md
docs/non_goals.md
docs/visual_overview.md
docs/images/visual-overview-editor-and-table.svg
docs/demo.md
docs/sandbox.md
docs/examples.md
docs/troubleshooting.md
docs/manual_qa.md
docs/release_checklist.md
docs/package_verification.md
docs/support_matrix.md
docs/controller_integration.md
docs/filter_metadata.md
docs/filter_adapters.md
docs/javascript_entrypoints.md
docs/javascript_controller.md
```

Keep this list synchronized with `RailsTablePreferences::PackageVerifier::REQUIRED_PATHS`. The runtime entries are representative helper, adapter, registry, formatter, and resource table files rather than a complete freeze of every file under `lib/`. The resource table partial entries guard the default `resource_table_for` and `tree_resource_table_for` rendering paths that a host app uses without custom partial configuration. The documentation entries are package entrances from the README and docs index rather than a complete freeze of every file under `docs/`.

## Package export targets

The package verification task reads the packaged `package.json` and confirms every string target under `exports` is included in the built gem. For the current package metadata, that means:

```text
. -> app/javascript/rails_table_preferences/index.js
./controller -> app/javascript/rails_table_preferences/controller.js
```

This check complements the fixed required-file list: the fixed list catches accidental removal of representative entrypoint files, while the export target check catches drift between `package.json` and the gem contents.

## Why this matters

The test suite can pass even if package contents are incomplete. Missing generator templates, copied JavaScript, copied CSS, package entrypoints, package metadata, rake tasks, changelog, visual overview assets, README-linked docs, or resource table runtime files usually appear only when the gem is installed into a host Rails app.

## Current CI gate

CI runs:

```bash
bundle exec rspec
node --check app/javascript/controllers/rails_table_preferences_controller.js
bundle exec rake build
bundle exec rake package:verify
```

The RSpec suite includes a JavaScript entrypoint smoke spec that loads the documented package root and controller entrypoints inside a minimal Node sandbox. That complements the syntax check and package file verification by guarding the export wiring itself.

Manual package inspection is still recommended before tagging a release.
