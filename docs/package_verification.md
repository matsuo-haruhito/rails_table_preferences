# Package verification

Use this guide after `bundle exec rake build` to confirm the gem package contains the files a host Rails application needs.

## Build

```bash
bundle exec rake build
```

This should create a `.gem` file under `pkg/`.

## Inspect package contents

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

Confirm the package includes at least:

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
lib/generators/rails_table_preferences/install/templates/demo_controller.rb
lib/generators/rails_table_preferences/install/templates/demo_index.html.erb
lib/generators/rails_table_preferences/javascript/javascript_generator.rb
lib/generators/rails_table_preferences/stylesheets/stylesheets_generator.rb
lib/generators/rails_table_preferences/views/views_generator.rb
lib/tasks/rails_table_preferences.rake
lib/rails_table_preferences.rb
lib/rails_table_preferences/export_payload.rb
lib/rails_table_preferences/settings_normalizer.rb
README.md
CHANGELOG.md
LICENSE
docs/index.md
```

## Why this matters

The test suite can pass even if package contents are incomplete. Missing generator templates, copied JavaScript, copied CSS, rake tasks, or docs usually appear only when the gem is installed into a host Rails app.

## Current CI gate

CI runs:

```bash
bundle exec rspec
node --check app/javascript/controllers/rails_table_preferences_controller.js
bundle exec rake build
```

Manual package inspection is still recommended before tagging a release.
