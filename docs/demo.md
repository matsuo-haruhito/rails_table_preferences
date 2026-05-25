# Demo screen generator

Rails Table Preferences can copy a lightweight demo screen into a host application for local browser verification.

Use this when you want to confirm the editor, table behavior, preference persistence, filters, and sortable headers before wiring the gem into a real business screen.

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

The copied rows intentionally include long-text columns, so you can verify header double-click auto-fit and overflow metadata without adding extra seed data.

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

## What the demo covers

The generated demo screen includes:

- Japanese column labels
- column visibility
- column order
- table-header drag ordering
- column width resizing
- double-click auto-fit on header resize handles
- truncation metadata and wrap overflow metadata on long-text columns
- preset save/load/delete UI
- bundled status feedback for async preset actions
- temporary busy-state disabling for preset controls and action buttons while bundled async preset actions run
- text/date/select filter metadata
- sortable header metadata
- ignored column metadata
- existing search form hidden fields

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
- [ ] Double-clicking the resize handle on `備考` auto-fits the column to the long text.
- [ ] `備考` and `配送メモ` show different ellipsis/wrap overflow behavior.
- [ ] Filter panel opens.
- [ ] Header click cycles sort state.
- [ ] Save persists settings.
- [ ] Reload restores saved settings.
- [ ] Save as new creates another preset.
- [ ] Delete removes a preset.
- [ ] Save, reload, save as new, and delete update the bundled status region with understandable progress and result copy.
- [ ] While save/load/delete actions run, the preset select, preset name, default checkbox, and action buttons are temporarily disabled and then re-enabled.
- [ ] If an async preset request fails, the bundled status region shows the generic failure state and the controls recover.

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

The demo screen is intentionally stable and small, so it can later be used as a target for Playwright or Selenium smoke tests.

Good first automated checks are:

- editor and table render
- hide column and apply
- save and reload restore settings
- filter panel opens
- sortable header changes sort state
