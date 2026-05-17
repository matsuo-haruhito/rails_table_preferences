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

The task checks the newest built gem under `pkg/` and fails if required runtime, generator, asset, task, changelog, or documentation files are missing.

A successful run prints a message like:

```text
Package verification passed: rails_table_preferences-0.1.0.alpha.gem
```

If required files are missing, the task prints the missing paths and exits with failure.

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
app/views/rails_table_preferences/_editor.html.erb
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
lib/rails_table_preferences/export_payload.rb
lib/rails_table_preferences/package_verifier.rb
lib/rails_table_preferences/settings_normalizer.rb
README.md
CHANGELOG.md
LICENSE
docs/index.md
docs/package_verification.md
```

Keep this list synchronized with `RailsTablePreferences::PackageVerifier::REQUIRED_PATHS`.

## Why this matters

The test suite can pass even if package contents are incomplete. Missing generator templates, copied JavaScript, copied CSS, rake tasks, changelog, or docs usually appear only when the gem is installed into a host Rails app.

## Current CI gate

CI runs:

```bash
bundle exec rspec
node --check app/javascript/controllers/rails_table_preferences_controller.js
bundle exec rake build
bundle exec rake package:verify
```

Manual package inspection is still recommended before tagging a release.
