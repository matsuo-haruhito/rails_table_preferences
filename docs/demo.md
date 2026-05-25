# Demo screen generator

Rails Table Preferences can copy a lightweight demo screen into a host application for local browser verification.

Use this when you want to confirm the editor, table behavior, preference persistence, filters, and sortable headers before wiring the gem into a real business screen.

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
- truncation metadata
- preset save/load/delete UI
- text/date/select filter metadata
- sortable header metadata
- ignored column metadata
- existing search form hidden fields

## What to check manually

On the demo screen, confirm:

- [ ] The editor appears above the table.
- [ ] The table appears with Japanese headers.
- [ ] The internal cost column does not appear.
- [ ] Apply hides and shows columns.
- [ ] Editor row drag changes column order.
- [ ] Table header drag changes column order.
- [ ] Header resize changes column width.
- [ ] Filter panel opens.
- [ ] Header click cycles sort state.
- [ ] Save persists settings.
- [ ] Reload restores saved settings.
- [ ] Save as new creates another preset.
- [ ] Delete removes a preset.

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