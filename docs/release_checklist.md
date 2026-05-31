# Release checklist

Use this checklist before tagging or publishing a Rails Table Preferences release.

The goal is to catch packaging, generator, documentation, and host-application integration issues that ordinary unit tests may miss.

## 1. Version and changelog

- [ ] Decide the target version.
- [ ] Update the version constant if needed.
- [ ] Move `CHANGELOG.md` entries from `[Unreleased]` to the target version section.
- [ ] Confirm `CHANGELOG.md` covers user-facing changes, migration changes, generator changes, JavaScript/CSS changes, and known limitations.
- [ ] Confirm the README and docs describe the released behavior, not planned behavior.
- [ ] Confirm examples use the current public API names.

## 2. Local automated checks

Run the minimum local checks:

```bash
bundle exec rspec
node --check app/javascript/controllers/rails_table_preferences_controller.js
bundle exec rake build
bundle exec rake package:verify
```

Representative Rails compatibility checks are also useful before a release:

```bash
BUNDLE_GEMFILE=gemfiles/rails_7_0.gemfile bundle exec rspec
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rspec
BUNDLE_GEMFILE=gemfiles/rails_7_2.gemfile bundle exec rspec
BUNDLE_GEMFILE=gemfiles/rails_8_0.gemfile bundle exec rspec
```

These Rails 7.0 / 7.1 / 7.2 / 8.0 checks match the current representative compatibility matrix. Newer host-app Rails releases, such as Rails 8.1, should be treated as additional verification work until a separate support-policy or CI-matrix decision adds them here.

Confirm:

- [ ] RSpec passes.
- [ ] JavaScript syntax check passes.
- [ ] Gem package builds.
- [ ] Package verification passes.
- [ ] Representative Rails 7.0 / 7.1 / 7.2 / 8.0 RSpec checks pass.
- [ ] No generated files are unexpectedly changed.

## 3. CI checks

Confirm GitHub Actions passes for both the release commit and the latest release-prep pull request:

- [ ] The release commit passes the default RSpec / JavaScript syntax / gem build / package verification job.
- [ ] The latest release-prep pull request passes the same default RSpec / JavaScript syntax / gem build / package verification job.
- [ ] The latest release-prep pull request passes the representative Rails 7.0, Rails 7.1, Rails 7.2, and Rails 8.0 compatibility jobs.
- [ ] Any additional release-time matrix jobs pass in the workflow where they actually run; they are not part of the required PR matrix unless `.github/workflows/ci.yml` adds them.

## 4. Gem package checks

Build and verify the gem package:

```bash
bundle exec rake build
bundle exec rake package:verify
```

Then optionally inspect the built gem or unpack it locally:

```bash
gem contents pkg/rails_table_preferences-*.gem --all
```

See [Package verification](package_verification.md) for the required file list and manual inspection commands.

Pay special attention to generator templates, copied assets, `package.json`, and package JavaScript entrypoints. Missing templates or entrypoints usually appear only when a host app runs a generator or imports the gem through a JS bundler.

## 5. Install generator checks

In a clean or disposable Rails app, run:

```bash
bin/rails generate rails_table_preferences:install
bin/rails db:migrate
```

Confirm:

- [ ] Initializer is created.
- [ ] Migration is created with valid index names.
- [ ] Migration includes `scope_type` and `scope_key`.
- [ ] Migration uses a nullable owner reference for shared, role, and organization presets.
- [ ] Migration runs on SQLite.
- [ ] Migration uses the configured owner model and foreign key when options are passed.
- [ ] JavaScript controller is copied by default.
- [ ] Stylesheet is copied by default.
- [ ] `--skip-javascript` skips JavaScript copying.
- [ ] `--skip-stylesheets` skips stylesheet copying.
- [ ] `--with-demo` copies the demo controller and view.
- [ ] Post-install messages are accurate for both `stimulus-rails` and Vite / `app/frontend` setups.

## 6. JavaScript entrypoint checks

For frontend integration, confirm:

- [ ] `app/javascript/controllers/rails_table_preferences_controller.js` is packaged for copy-based `stimulus-rails` use.
- [ ] `app/javascript/rails_table_preferences/controller.js` is packaged for `rails_table_preferences/controller` imports.
- [ ] `app/javascript/rails_table_preferences/index.js` is packaged for package-root imports.
- [ ] `package.json` is packaged and exposes `.` and `./controller` exports.
- [ ] A Vite / `app/frontend/entrypoints/application.js` host app can register `rails_table_preferences/controller` as `rails-table-preferences`.
- [ ] A default `stimulus-rails` host app still works with the copied controller.

## 7. Demo and sandbox checks

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
- [ ] The `Current owner` summary matches the owner record that save/reload will persist into.
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
- [ ] Fixed/pinned column hooks are present when configured.
- [ ] The grouped header row still matches the visible leaf headers after changing visibility or order, saving, and reloading.
- [ ] Read-only scoped presets do not expose destructive normal-user controls.
- [ ] The `Current scope context` summary matches the scope context returned by the host app.
- [ ] Shared preset examples appear in the preset selector.
- [ ] Matching role context shows the role preset example in the preset selector.
- [ ] Matching organization context shows the organization preset example in the preset selector.
- [ ] With no owner default, role default resolution still wins before organization and shared defaults.
- [ ] With no owner or matching role default, organization default resolution still wins before shared defaults.
- [ ] The export payload preview excludes hidden columns by default.
- [ ] The export payload preview follows the saved visible-column order.
- [ ] Async preset actions update the bundled status region with understandable progress and result copy.
- [ ] Async preset actions temporarily disable controls and recover after success or failure.

See also:

- [Demo screen generator](demo.md)
- [Sandbox Rails app verification](sandbox.md)
- [Manual QA checklist](manual_qa.md)

## 8. API and controller behavior checks

Confirm the mounted engine JSON API still behaves as expected:

- [ ] `GET /rails_table_preferences/preferences/:table_key`
- [ ] `POST /rails_table_preferences/preferences/:table_key`
- [ ] `GET /rails_table_preferences/preferences/:table_key/:name`
- [ ] `PATCH /rails_table_preferences/preferences/:table_key/:name`
- [ ] `PUT /rails_table_preferences/preferences/:table_key/:name`
- [ ] `DELETE /rails_table_preferences/preferences/:table_key/:name`

Confirm scoped preference behavior:

- [ ] Owner presets are editable by the owner.
- [ ] Shared presets can be selected by users.
- [ ] Role presets are available only when the scope context matches.
- [ ] Organization presets are available only when the scope context matches.
- [ ] Default resolution prefers owner, then role, then organization, then shared.

Confirm controller integration behavior:

- [ ] `rails_table_preference_settings` returns normalized settings.
- [ ] `rails_table_preference_params` returns plain controller params by default.
- [ ] `rails_table_preference_params(adapter: :ransack)` returns Ransack params.
- [ ] `rails_table_preference_merged_params` merges with host controller params.
- [ ] `rails_table_preference_export_payload` returns ordered export columns and headers.
- [ ] Private current-owner methods work.

## 9. Documentation checks

Check the main user paths:

- [ ] README links to Quick start.
- [ ] README links to Decision guide.
- [ ] README links to Scoped presets.
- [ ] README links to Fixed columns and column groups.
- [ ] README links to Export integration.
- [ ] README links to Accessibility baseline.
- [ ] README links to Demo screen generator.
- [ ] README links to Sandbox verification.
- [ ] README links to Troubleshooting.
- [ ] README links to Manual QA.
- [ ] README links to Release checklist.
- [ ] README links to Package verification.
- [ ] README links to JavaScript entrypoints.
- [ ] `docs/index.md` links to all major docs.
- [ ] README remains a short newcomer-facing entry point, while `docs/index.md` remains the detailed hub for current focused guides.
- [ ] `Product Profile.md` is synchronized with the released product surface, responsibility boundary, and release posture without copying focused guide details.
- [ ] Installation docs mention engine mount.
- [ ] Installation docs mention Vite / `app/frontend` controller registration.
- [ ] Demo docs clearly say the demo route must be added manually.
- [ ] `docs/demo.md`, `docs/manual_qa.md`, and `docs/release_checklist.md` stay aligned on the current demo verification surface, including owner/scope summaries, scoped preset precedence, export payload preview, grouped-header consistency, and async preset recovery.
- [ ] Troubleshooting covers Stimulus, Vite entrypoints, CSS, CSRF, auth, current user, scoped presets, filter/sort, and ignored columns.
- [ ] Responsibility boundary is clear: host app owns database search, authorization, complex sticky layout polish, export file generation, and shared preset admin UI.

## 10. Backward compatibility checks

If changing settings structure, helper options, or JSON API shape, confirm:

- [ ] `SettingsNormalizer` still accepts legacy `ColumnAdjustment`-style keys.
- [ ] Existing saved settings do not reintroduce ignored columns.
- [ ] Missing filters/sorts normalize to empty neutral values.
- [ ] Existing controller params adapter behavior is preserved.
- [ ] Existing Ransack adapter behavior is preserved.
- [ ] Current column metadata overrides stale saved metadata for labels, filters, sortable state, and pinned state.
- [ ] Run the display preference behavior section in [Manual QA checklist](manual_qa.md) when changing column labels, overflow metadata, fixed/pinned metadata, or reset/default handling.

## 11. Release notes

Before publishing, summarize:

- [ ] New features.
- [ ] Breaking changes, if any.
- [ ] Migration or generator changes.
- [ ] JavaScript/CSS integration changes.
- [ ] Known limitations.
- [ ] Upgrade notes for existing users.

## 12. Publish or tag

When everything is ready:

- [ ] Ensure the working tree is clean.
- [ ] Tag the release.
- [ ] Push the tag.
