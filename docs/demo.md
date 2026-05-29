# Demo screen generator

Rails Table Preferences can copy a lightweight demo screen into a host application for local browser verification.

Use this when you want to confirm the editor, table behavior, preference persistence, filters, sortable headers, fixed columns, and column groups before wiring the gem into a real business screen.

For a quick visual reference before generating the screen locally, see [Visual overview](visual_overview.md).

## Generate demo files

Run the install generator with `--with-demo`:

```bash
bin/rails generate rails_table_preferences:install --with-demo
bin/rails db:migrate
```

This copies the normal installation files plus:

```text
app/controllers/rails_table_preferences_demo/orders_controller.rb
app/views/rails_table_preferences_demo/orders/index.html.erb
```

The demo controller uses in-memory order rows for display. It does not create an orders table. Preference persistence still uses the normal `table_preferences` table and the mounted engine API.

The generated screen also seeds one shared preset named `共有ビュー`. This gives you a minimal way to confirm that a normal owner can load a shared preset, cannot delete it from the normal editor, and saves changes back into an owner preset instead of overwriting the shared preset.

The same demo controller also seeds one role preset named `担当ビュー` for the role key `operations`. After you enable the example scope context shown below, the selector shows `担当ビュー [role:operations]` and default resolution prefers it over the shared preset while no owner default exists.

The same demo controller also seeds one organization preset named `東京組織ビュー` for the organization key `tokyo-hq`. If you return that organization without a matching owner or role default, the selector shows `東京組織ビュー [organization:tokyo-hq]` and default resolution prefers it over the shared preset.

The sample rows are intentionally a little more practical than a three-row placeholder. They mix repeated customer prefixes (`東京...`), multiple statuses, varied delivery dates, long shipping codes, long delivery notes, and memo lengths so sort, filter, width, auto-fit, and overflow checks are easier to judge at a glance.

The same screen now includes a lightweight export payload preview. It shows the ordered `headers` and `column_keys` that the current saved table settings would pass into `rails_table_preference_export_payload(...)`, so you can confirm hidden-column exclusion and saved order without wiring a real CSV action first.

The demo table also keeps `受注番号` pinned inside a dedicated horizontal scroll wrapper and renders a grouped header row (`受注情報` / `得意先情報` / `配送情報`). This gives you one narrow place to verify both fixed-column and column-group behavior before adding custom host-app table markup, and the grouped header follows the current visible columns after save/reload.

## Add routes

Mount the engine if it is not already mounted:

```ruby
# config/routes.rb
mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
```

Add the demo route:

```ruby
# config/routes.rb
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

Then open:

```text
http://localhost:3000/rails_table_preferences_demo/orders
```

## Requirements

The demo uses the configured current-user method. By default, Rails Table Preferences calls `current_user`.

For a quick sandbox app, define a simple current user method:

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_user

  private

  def current_user
    User.first_or_create!(name: "Sandbox User")
  end
end
```

If the host app uses another owner model or method, configure it in the initializer:

```ruby
RailsTablePreferences.configure do |config|
  config.owner_model = :customers
  config.current_user_method = :current_customer
end
```

## Optional scoped demo context

To activate the generated role and organization preset examples, configure `scope_context_method` once and point it at the generated demo controller method:

```ruby
RailsTablePreferences.configure do |config|
  config.scope_context_method = :table_preference_scope_context
end
```

After that one-time setup, the generated demo gives you four small links near the top of the page:

- `Host app context`
- `Owner-only baseline`
- `Role preset lane`
- `Organization preset lane`

Use those links to move between the shared baseline, the representative role scope, and the representative organization scope without editing `ApplicationController` between requests.

The generated screen also shows a lightweight `Current scope context` summary near the top. Use it to confirm whether the current request is still `owner-only` or already includes representative `roles` / `organization` keys before reading the preset selector.

The role link forces this representative scope:

```ruby
{ roles: ["operations"] }
```

The organization link forces this representative scope:

```ruby
{ organization: "tokyo-hq" }
```

With both demo presets seeded, those links make it easier to compare the selector and default resolution paths in one browser session:

- `Owner-only baseline` returns to the shared baseline with no scoped keys.
- `Role preset lane` makes the selector include `担当ビュー [role:operations]` and, with no owner default, reloading still resolves it before the shared preset.
- `Organization preset lane` makes the selector include `東京組織ビュー [organization:tokyo-hq]` and, with no owner or matching role default, reloading still resolves it before the shared preset.

If you already created an owner default while testing Save or Save as new, clear it before checking role/organization precedence. In the bundled editor, load the owner preset, uncheck `標準設定にする`, save, then reload. Deleting that temporary owner preset also works when you only created it for demo verification. The important part is to return to a state where no owner preset for this table is marked as default, because owner defaults always win before role, organization, and shared defaults.

## What the demo covers

The generated demo screen includes:

- Japanese column labels
- sample rows with repeated customer prefixes, varied status/date values, and long delivery notes for practical sort, filter, width, auto-fit, and overflow checks
- column visibility
- column order
- table-header drag ordering
- column width resizing
- double-click auto-fit on header resize handles
- wrap / nowrap / ellipsis overflow examples on the same screen
- fixed/pinned column metadata inside a horizontal scroll wrapper
- grouped header markup that mirrors column group metadata
- truncation metadata
- preset save/load/delete UI
- one shared preset example with read-only fallback behavior
- one role preset example for `roles: ["operations"]`, including role-over-shared default resolution
- one organization preset example for `organization: "tokyo-hq"`, including organization-over-shared default resolution when no owner or matching role default exists
- bundled status feedback for async preset actions
- temporary busy-state disabling for preset controls and action buttons while bundled async preset actions run
- text/date/select filter metadata
- sortable header metadata
- ignored column metadata
- existing search form hidden fields
- export payload preview for ordered `headers` and `column_keys`

For the accessibility-side contract behind these checks, see [Accessibility baseline](accessibility.md).

## What to check manually

On the demo screen, confirm:

- [ ] The editor appears above the table.
- [ ] The table appears with Japanese headers.
- [ ] The internal cost column does not appear.
- [ ] Apply hides and shows columns.
- [ ] Editor row drag changes column order.
- [ ] Table header drag changes column order.
- [ ] Header resize changes column width.
- [ ] Double-clicking the resize handle on `配送メモ` or `配送コード` expands the column to fit its content more closely.
- [ ] `配送メモ` wraps, `配送コード` stays on one line, and `備考` uses ellipsis so the overflow mode differences are visible.
- [ ] Horizontally scrolling the demo wrapper keeps `受注番号` visible.
- [ ] After changing visibility or order, saving, and reloading, the grouped header row still matches the visible leaf headers.
- [ ] Filter panel opens.
- [ ] Searching for `東京` narrows the list to multiple matching rows.
- [ ] Header click cycles sort state.
- [ ] Sorting by `納品日` or `金額` makes the row order visibly change.
- [ ] Save persists settings.
- [ ] Reload restores saved settings.
- [ ] Save as new creates another preset.
- [ ] `共有ビュー [shared]` appears in the preset selector.
- [ ] Selecting `共有ビュー [shared]` loads the shared preset and keeps the normal editor usable.
- [ ] While `共有ビュー [shared]` is selected, delete stays disabled for the normal user-facing editor.
- [ ] Saving after selecting `共有ビュー [shared]` creates or updates an owner preset instead of overwriting the shared preset.
- [ ] After enabling `scope_context_method = :table_preference_scope_context`, the `Host app context`, `Owner-only baseline`, `Role preset lane`, and `Organization preset lane` links switch the current scope without editing application code.
- [ ] The `Current scope context` summary matches whichever scope link is active.
- [ ] `Owner-only baseline` returns the summary to `owner-only` and makes it easy to compare the shared baseline again.
- [ ] `Role preset lane` makes `担当ビュー [role:operations]` appear in the selector.
- [ ] With that role context and no owner default, reloading the demo resolves `担当ビュー [role:operations]` before `共有ビュー [shared]`.
- [ ] `Organization preset lane` makes `東京組織ビュー [organization:tokyo-hq]` appear in the selector.
- [ ] With that organization context and no owner or matching role default, reloading the demo resolves `東京組織ビュー [organization:tokyo-hq]` before `共有ビュー [shared]`.
- [ ] Delete removes a preset.
- [ ] Save, reload, save as new, and delete update the bundled status region with understandable progress and result copy.
- [ ] While save/load/delete actions run, the preset select, preset name, default checkbox, and action buttons are temporarily disabled and then re-enabled.
- [ ] If an async preset request fails, the bundled status region shows the generic failure state and the controls recover.
- [ ] The export payload preview excludes hidden columns by default.
- [ ] After saving a new visible-column order, the export payload preview shows the same header order and column key order.

## Reproduce one async failure quickly

Use browser devtools to block one preference API request once, instead of changing application code just for QA.

1. Open the demo screen and browser devtools.
2. In Network request blocking or an equivalent tool, block the mounted preference API path for the current table, such as `/rails_table_preferences/preferences/orders` or `/rails_table_preferences/preferences/orders/default`.
3. Trigger one async preset action:
   - Save or Save as new for `POST`/`PATCH`
   - Switch presets for `GET`
   - Delete for `DELETE`
4. Confirm the bundled status region moves from the in-progress copy to the generic failure copy.
5. Confirm the preset select, preset name, default checkbox, and action buttons become usable again after the failed request.
6. Remove the request block and retry once to confirm the same action succeeds normally.

If the host app mounts the engine at a custom path, block that configured `mount_path` instead of `/rails_table_preferences`.

## Production note

The demo files are intended for development and verification only.

Remove these files before production release if they are not needed:

```text
app/controllers/rails_table_preferences_demo/orders_controller.rb
app/views/rails_table_preferences_demo/orders/index.html.erb
```

Also remove the demo route:

```ruby
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

## Relationship to automated browser tests

The demo screen is intentionally stable and small, and the repository now keeps one equivalent demo-shaped browser smoke under automated coverage.

Current automated browser/system smoke covers:

- editor and table render
- hide column and apply
- active filter button summary through `title` / `aria-label`
- bundled filter panel close on viewport resize
- existing search form submit with saved hidden-field filter and sort state
- export payload preview hidden-column exclusion and saved visible-column order
- filter operator switch updates the in-panel fields in place
- double-click auto-fit and overflow-mode surface on representative demo columns
- bundled filter panel close on page scroll

Good next automated checks are:

- save and reload restore settings
- sortable header click changes sort state directly
- bundled filter panel close on container scroll
