# Release checklist

Use this checklist before tagging or publishing a Rails Table Preferences release.

The goal is to catch packaging, generator, documentation, and host-application integration issues that ordinary unit tests may miss.

## 1. Version and changelog

- [ ] Decide the target version.
- [ ] Update the version constant if needed.
- [ ] Update `CHANGELOG.md` with user-facing changes.
- [ ] Confirm the README and docs describe the released behavior, not planned behavior.
- [ ] Confirm examples use the current public API names.

## 2. Local automated checks

Run the minimum local checks:

```bash
bundle exec rspec
node --check app/javascript/controllers/rails_table_preferences_controller.js
```

Confirm:

- [ ] RSpec passes.
- [ ] JavaScript syntax check passes.
- [ ] No generated files are unexpectedly changed.

## 3. CI checks

Confirm GitHub Actions passes for the release commit:

- [ ] Ruby test job passes.
- [ ] JavaScript syntax check passes.
- [ ] Any future matrix jobs pass.

## 4. Gem package checks

Build the gem package:

```bash
bundle exec rake build
```

Then inspect the built gem or unpack it locally and confirm it includes:

- [ ] `lib/**/*`
- [ ] `app/controllers/**/*`
- [ ] `app/controllers/concerns/**/*`
- [ ] `app/helpers/**/*`
- [ ] `app/views/**/*`
- [ ] `app/javascript/**/*`
- [ ] `app/assets/**/*`
- [ ] `lib/generators/**/*`
- [ ] `lib/tasks/**/*`
- [ ] `docs/**/*`
- [ ] `README.md`
- [ ] `LICENSE`
- [ ] `rails_table_preferences.gemspec`

Pay special attention to generator templates and copied assets. Missing templates usually appear only when a host app runs a generator.

## 5. Install generator checks

In a clean or disposable Rails app, run:

```bash
bin/rails generate rails_table_preferences:install
bin/rails db:migrate
```

Confirm:

- [ ] Initializer is created.
- [ ] Migration is created with valid index names.
- [ ] Migration runs on SQLite.
- [ ] Migration uses the configured owner model and foreign key when options are passed.
- [ ] JavaScript controller is copied by default.
- [ ] Stylesheet is copied by default.
- [ ] `--skip-javascript` skips JavaScript copying.
- [ ] `--skip-stylesheets` skips stylesheet copying.
- [ ] `--with-demo` copies the demo controller and view.
- [ ] Post-install messages are accurate.

## 6. Demo and sandbox checks

Run through the demo or sandbox flow:

```bash
bin/rails generate rails_table_preferences:install --with-demo
bin/rails db:migrate
```

Add the required routes:

```ruby
mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

Confirm:

- [ ] The demo page renders.
- [ ] The host app has a working current owner method, usually `current_user`.
- [ ] Private `current_user` methods work.
- [ ] Japanese demo labels render.
- [ ] Ignored demo columns do not appear in the editor.
- [ ] Column visibility works.
- [ ] Column order works from the editor.
- [ ] Column order works from table-header drag.
- [ ] Column width resize works.
- [ ] Save persists settings.
- [ ] Reload restores saved settings.
- [ ] Filter panel opens.
- [ ] Sortable header click cycles sort state.

See also:

- [Demo screen generator](demo.md)
- [Sandbox Rails app verification](sandbox.md)
- [Manual QA checklist](manual_qa.md)

## 7. API and controller behavior checks

Confirm the mounted engine JSON API still behaves as expected:

- [ ] `GET /rails_table_preferences/preferences/:table_key`
- [ ] `POST /rails_table_preferences/preferences/:table_key`
- [ ] `GET /rails_table_preferences/preferences/:table_key/:name`
- [ ] `PATCH /rails_table_preferences/preferences/:table_key/:name`
- [ ] `PUT /rails_table_preferences/preferences/:table_key/:name`
- [ ] `DELETE /rails_table_preferences/preferences/:table_key/:name`

Confirm controller integration behavior:

- [ ] `rails_table_preference_settings` returns normalized settings.
- [ ] `rails_table_preference_params` returns plain controller params by default.
- [ ] `rails_table_preference_params(adapter: :ransack)` returns Ransack params.
- [ ] `rails_table_preference_merged_params` merges with host controller params.
- [ ] Private current-owner methods work.

## 8. Documentation checks

Check the main user paths:

- [ ] README links to Quick start.
- [ ] README links to Decision guide.
- [ ] README links to Demo screen generator.
- [ ] README links to Sandbox verification.
- [ ] README links to Troubleshooting.
- [ ] README links to Manual QA.
- [ ] `docs/index.md` links to all major docs.
- [ ] Installation docs mention engine mount.
- [ ] Demo docs clearly say the demo route must be added manually.
- [ ] Troubleshooting covers Stimulus, CSS, CSRF, auth, current user, filter/sort, and ignored columns.
- [ ] Responsibility boundary is clear: host app owns database search and authorization.

## 9. Backward compatibility checks

If changing settings structure, helper options, or JSON API shape, confirm:

- [ ] `SettingsNormalizer` still accepts legacy `ColumnAdjustment`-style keys.
- [ ] Existing saved settings do not reintroduce ignored columns.
- [ ] Missing filters/sorts normalize to empty neutral values.
- [ ] Existing controller params adapter behavior is preserved.
- [ ] Existing Ransack adapter behavior is preserved.

## 10. Release notes

Before publishing, summarize:

- [ ] New features.
- [ ] Breaking changes, if any.
- [ ] Migration or generator changes.
- [ ] JavaScript/CSS integration changes.
- [ ] Known limitations.
- [ ] Upgrade notes for existing users.

## 11. Publish or tag

When everything is ready:

- [ ] Ensure the working tree is clean.
- [ ] Tag the release.
- [ ] Push the tag.
- [ ] Publish the gem if releasing to RubyGems.
- [ ] Create GitHub release notes.

## Current lightweight release gate

For the current early release stage, the minimum gate is:

```bash
bundle exec rspec
node --check app/javascript/controllers/rails_table_preferences_controller.js
bundle exec rake build
```

Plus one successful sandbox/demo verification before asking real application users to try the release.
