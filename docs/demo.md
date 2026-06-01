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

If you also want the generator to add the demo route to `config/routes.rb`, use `--with-demo-route`. This implies `--with-demo`, copies the same demo files, and skips adding a duplicate route when the route already exists:

```bash
bin/rails generate rails_table_preferences:install --with-demo-route
bin/rails db:migrate
```

The demo controller uses in-memory order rows for display. It does not create an orders table. Preference persistence still uses the normal `table_preferences` table and the mounted engine API.

The generated screen also seeds one shared preset named `共有ビュー`. This gives you a minimal way to confirm that a normal owner can load a shared preset, cannot delete it from the normal editor, and saves changes back into an owner preset instead of overwriting the shared preset.

The same demo controller also seeds one role preset named `担当ビュー` for the role key `operations`. After you enable the example scope context shown below, the selector shows `担当ビュー [role:operations]` and default resolution prefers it over the shared preset while no owner default exists.

The same demo controller also seeds one organization preset named `東京組織ビュー` for the organization key `tokyo-hq`. If you return that organization without a matching owner or role default, the selector shows `東京組織ビュー [organization:tokyo-hq]` and default resolution prefers it over the shared preset.

The sample rows are intentionally a little more practical than a three-row placeholder. They mix repeated customer prefixes (`東京...`), multiple statuses, true/false confirmation states, varied amounts, varied delivery dates, long shipping codes, long delivery notes, and memo lengths so sort, filter, width, auto-fit, and overflow checks are easier to judge at a glance.

The same screen now includes a lightweight export payload preview. It shows the ordered `headers` and `column_keys` that the current saved table settings would pass into `rails_table_preference_export_payload(...)`, so you can confirm hidden-column exclusion and saved order without wiring a real CSV action first.

The demo table also keeps `受注番号` pinned inside a dedicated horizontal scroll wrapper and renders a grouped header row (`受注情報` / `得意先情報` / `配送情報`). This gives you one narrow place to verify both fixed-column and column-group behavior before adding custom host-app table markup, and the grouped header follows the current visible columns after save/reload.

The generated screen also includes a `Demo state reset` button. Use it to delete owner-scoped presets for the current owner and demo table, then reload into the seeded shared / role / organization baseline before repeating scoped precedence checks.

The generated screen also includes an `Async failure check` button. Use it when you want the next preset save, load, or delete request to fail exactly once, then retry the same action to confirm the bundled status region and controls recover without browser request blocking.

## Add routes

Mount the engine if it is not already mounted:

```ruby
# config/routes.rb
mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
```

If you generated with `--with-demo-route`, the install generator adds the demo route for you. Otherwise, add it manually:

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

When the generated demo loads, it also shows a small `Current owner` summary with the owner model, display name, and identifier. Use that summary as a quick check that `Save` and `Save as new` will persist back into the owner record you expect, especially after loading `共有ビュー [shared]`.

The generated screen also adds demo-only owner links near the top of the page:

- `Host app owner`
- `Demo owner A`
- `Demo owner B`

Use those links to save once as one owner, switch to another owner, and confirm presets do not leak between owner records without editing authentication code between requests.

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

If you already created owner-scoped presets while testing Save or Save as new, click `Reset demo verification state` before checking role/organization precedence again. The demo reset deletes editable owner presets for the current owner and demo table through the normal mounted preset API, then reloads so the seeded shared / role / organization examples are still present. This is a demo-only cleanup helper; it is not a production preset-management or authorization surface.

## What the demo covers

The generated demo screen includes:

- Japanese column labels
- sample rows with repeated customer prefixes, varied status/date/amount values, true/false confirmation states, and long delivery notes for practical sort, filter, width, auto-fit, and overflow checks
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
- demo-only owner preset reset for returning to the seeded baseline
- bundled status feedback for async preset actions
- temporary busy-state disabling for preset controls and action buttons while bundled async preset actions run
- one-shot async failure trigger for demo-only preset save/load/delete recovery checks
- text/date/select/boolean/number filter metadata
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
- [ ] `確認済` exposes the boolean filter operators and its sample rows include both true and false values.
- [ ] `金額` exposes number filter operators with a number input, and saving `金額 >= 50000` narrows the rows to the larger sample amounts after reload.
- [ ] Searching for `東京` narrows the list to multiple matching rows.
- [ ] Header click cycles sort state.
- [ ] Sorting by `納品日` or `金額` makes the row order visibly change.
- [ ] Save persists settings.
- [ ] Reload restores saved settings.
- [ ] Save as new creates another preset.
- [ ] `共有ビュー [shared]` appears in the preset selector.
- [ ] Selecting `共有ビュー [shared]` loads the shared preset and keeps the normal editor usable.
- [ ] While `共有ビュー [shared]` is selected, delete stays disabled for the normal user-facing editor.
- [ ] The `Current owner` summary matches the owner record that shared-preset fallback saves back into.
- [ ] `Host app owner`, `Demo owner A`, and `Demo owner B` switch the owner context without editing application code.
- [ ] After switching owners, the `Current owner` summary follows the active owner link.
- [ ] Saving under `Demo owner A`, then switching to `Demo owner B`, makes it easy to confirm those presets do not leak across owners.
- [ ] Saving after selecting `共有ビュー [shared]` creates or updates an owner preset instead of overwriting the shared preset.
- [ ] `Reset demo verification state` removes owner-scoped presets for the current owner and table, then reloads with `共有ビュー`, `担当ビュー`, and `東京組織ビュー` still available.
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
- [ ] The `Async failure check` button makes the next preset save, load, or delete request fail exactly once.
- [ ] If an async preset request fails, the bundled status region shows the generic failure state and the controls recover.
- [ ] Retrying the same preset action after the one-shot failure succeeds normally.
- [ ] The export payload preview excludes hidden columns by default.
- [ ] After saving a new visible-column order, the export payload preview shows the same header order and column key order.

## Reset demo state before scoped checks

Use the generated `Demo state reset` section when previous save testing left owner-scoped presets behind and you want to repeat role / organization default resolution from a clean owner baseline.

1. Open the demo screen with the owner you want to clean up.
2. Click `Reset demo verification state`.
3. Wait for the success message and reload.
4. Confirm owner-scoped presets for the current table are gone while `共有ビュー [shared]`, `担当ビュー [role:operations]`, and `東京組織ビュー [organization:tokyo-hq]` remain available when their scopes match.
5. Use `Owner-only baseline`, `Role preset lane`, or `Organization preset lane` to repeat the scoped precedence checks without manually unchecking `標準設定にする` or deleting temporary owner presets one by one.

## Reproduce one async failure quickly

Use the generated `Async failure check` section to fail one preset API request once, without changing application code or opening browser request-blocking tools.

1. Open the demo screen.
2. Click `Fail next preset request once`.
3. Trigger one async preset action:
   - Save or Save as new for `POST`/`PATCH`
   - Switch presets for `GET`
   - Delete for `DELETE`
4. Confirm the bundled status region moves from the in-progress copy to the generic failure copy.
5. Confirm the preset select, preset name, default checkbox, and action buttons become usable again after the failed request.
6. Retry the same action once to confirm it succeeds normally; the demo trigger is one-shot and does not keep blocking requests.

If you need to test a custom host-app wrapper outside the generated demo, browser devtools request blocking is still a useful fallback. Block the configured `mount_path` for one request, then unblock it before retrying.

## Strict CSP in host applications

The generated demo is a development verification surface. To keep the copied files self-contained, the demo view includes inline style and inline script for the sample screen, the demo state reset helper, and the one-shot async failure helper.

When Rails exposes `content_security_policy_nonce`, the generated demo adds the current request nonce to those inline `<style>` and `<script>` blocks. In host applications whose development CSP allows Rails nonces for `style-src` and `script-src`, the demo-only styling, reset helper, and async failure helper can run without adding a separate demo asset pipeline or generator option.

If the host application runs a strict Content Security Policy in development but does not allow those nonces, the inline blocks may still be blocked. Symptoms can include missing demo-only styling, owner/scope switch helpers not behaving as expected, the `Reset demo verification state` button not deleting owner-scoped presets, or the `Async failure check` button not triggering the next request failure.

When that happens, check the browser console and any CSP report endpoint for blocked inline `style-src` or `script-src` entries. For local verification, allow Rails nonces for the copied demo route under a development-only policy, allow the copied demo route under another development-only policy, or manually delete owner-scoped demo presets through the normal preset UI before scoped checks. Do not treat the generated demo as the production admin surface; the production path is still to remove the demo files and route when they are not needed.

## Production note

The demo files are intended for development and verification only.

Remove these files before production release if they are not needed:

```text
app/controllers/rails_table_preferences_demo/orders_controller.rb
app/views/rails_table_preferences_demo/orders/index.html.erb
```

Also remove the demo route, including routes added by `--with-demo-route`:

```ruby
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

## Relationship to automated browser tests

The demo screen is intentionally stable and small, and the repository now keeps one equivalent demo-shaped browser smoke under automated coverage.

Current automated browser/system smoke covers:

- editor and table render
- hide column and apply
- active filter button summary through `title` / `aria-label`
- bundled filter panel `Escape` close with focus return to the trigger button
- bundled filter panel close on viewport resize
- preset-load failure busy-state disable and recovery on the bundled controls
- existing search form submit with saved hidden-field filter and sort state
- export payload preview hidden-column exclusion and saved visible-column order
- filter operator switch updates the in-panel fields in place
- double-click auto-fit and overflow-mode surface on representative demo columns
- bundled filter panel close on page scroll

Good next automated checks are:

- shared preset read-only load and owner-fallback save
- save and reload restore settings
- sortable header click changes sort state directly
- bundled filter panel close on container scroll
- one-shot async failure trigger from the generated demo surface
- demo-only reset removes owner-scoped presets before scoped default precedence checks