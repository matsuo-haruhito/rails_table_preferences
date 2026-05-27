# Quick start

This guide shows the shortest path from installation to a working table preference UI.

## 1. Add the gem

For local development against this repository:

```ruby
# Gemfile
gem "rails_table_preferences", path: "../rails_table_preferences"
```

For normal usage after release, use the released gem version instead.

Then install dependencies:

```bash
bundle install
```

## 2. Run the install generator

For the default `User` owner model:

```bash
bin/rails generate rails_table_preferences:install
```

For another owner model, pass `--owner-model`. The value can be singular or plural:

```bash
bin/rails generate rails_table_preferences:install --owner-model customers
bin/rails generate rails_table_preferences:install --owner-model client
```

The generator copies:

- a migration into `db/migrate`
- `config/initializers/rails_table_preferences.rb`
- `app/javascript/controllers/rails_table_preferences_controller.js`
- `app/assets/stylesheets/rails_table_preferences.css`

Run the migration:

```bash
bin/rails db:migrate
```

### If the host app does not use `User` / `current_user`

When the host app uses another owner model or another current-owner method, set both in the initializer before trying the demo or bundled JSON API:

```ruby
RailsTablePreferences.configure do |config|
  config.owner_model = :customers
  config.current_user_method = :current_customer
end
```

The configured method must return a persisted record for the configured owner model. A minimal sandbox setup looks like this:

```ruby
class ApplicationController < ActionController::Base
  helper_method :current_customer

  private

  def current_customer
    Customer.first_or_create!(name: "Sandbox Customer")
  end
end
```

This matters for both the normal editor flow and the copied demo screen. `--with-demo` does not create the owner record for you; it reuses the same configured current-owner method as the rest of the gem.

### Vite / app/frontend entrypoint registration

When your app uses `app/frontend/entrypoints/application.js` instead of the default `stimulus-rails` controller manifest, register the controller explicitly from the gem entrypoint:

```js
import { Application } from "@hotwired/stimulus"
import RailsTablePreferencesController from "rails_table_preferences/controller"

const application = Application.start()
application.register("rails-table-preferences", RailsTablePreferencesController)
```

The `rails_table_preferences` package also exports the controller as a named export:

```js
import { RailsTablePreferencesController } from "rails_table_preferences"
```

The generator still copies `app/javascript/controllers/rails_table_preferences_controller.js` for Rails apps that rely on `stimulus-rails` default manifests. Vite apps can use the package entrypoint above to avoid depending on that copied path from `app/frontend`.

## 3. Mount the engine

Add the JSON API route used by the bundled editor:

```ruby
# config/routes.rb
mount RailsTablePreferences::Engine, at: "/rails_table_preferences"
```

If you change the mount path, set the same value in the initializer:

```ruby
RailsTablePreferences.configure do |config|
  config.mount_path = "/rails_table_preferences"
end
```

## 4. Define columns

Define the table columns in the controller, helper, or another view-friendly place.

```ruby
@table_columns = [
  table_preferences_column(:order_no, label: "受注番号", default_width: 120),
  table_preferences_column(:customer_name, label: "得意先名", default_width: 240, overflow: :ellipsis),
  table_preferences_column(:delivery_date, label: "納品日", default_width: 140)
]
```

Column labels are the user-facing names shown in the preference editor. By default, Rails Table Preferences resolves them in this order:

1. `label:` passed to `table_preferences_column`
2. `i18n_key:` passed to `table_preferences_column`
3. database column comment from `model.columns_hash[key].comment`

If no label can be resolved, the column is hidden from Rails Table Preferences, the same as `ignored: true`. This avoids exposing columns that have not been marked as user-facing.

You can use database comments by passing an Active Record model class:

```ruby
@table_columns = [
  table_preferences_column(:order_no, model: Order, default_width: 120),
  table_preferences_column(:customer_name, model: Order, default_width: 240, overflow: :ellipsis),
  table_preferences_column(:delivery_date, model: Order, default_width: 140)
]
```

You can also resolve one column through a custom translation key:

```ruby
table_preferences_column(:customer_name, i18n_key: "orders.index.columns.customer_name")
```

For host apps that want Rails-style attribute locale keys, add those rules in the initializer:

```ruby
RailsTablePreferences.configure do |config|
  config.label_resolution = %i[
    label
    i18n_key
    column_comment
    activerecord_attribute_i18n
    activemodel_attribute_i18n
    attribute_i18n
  ]
end
```

Then add host app locale entries:

```yaml
ja:
  activerecord:
    attributes:
      order:
        order_no: 受注番号
        customer_name: 得意先名
        delivery_date: 納品日
```

If you prefer the old permissive fallback style, include `:humanize` or set the unresolved behavior:

```ruby
RailsTablePreferences.configure do |config|
  config.label_resolution = %i[label i18n_key column_comment humanize]
  # or:
  config.unresolved_label_behavior = :humanize
end
```

## 5. Render the editor and table

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: @table_columns,
  title: "受注一覧の表示設定"
) %>

<%= table_preferences_table_tag(
  table_key: :orders,
  columns: @table_columns,
  class: "table"
) do %>
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="order_no">受注番号</th>
      <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
      <th data-rails-table-preferences-column-key="delivery_date">納品日</th>
    </tr>
  </thead>
  <tbody>
    <% @orders.each do |order| %>
      <tr>
        <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
        <td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
        <td data-rails-table-preferences-column-key="delivery_date"><%= l(order.delivery_date) if order.delivery_date %></td>
      </tr>
    <% end %>
  </tbody>
<% end %>
```

The `data-rails-table-preferences-column-key` values must match the keys passed to `table_preferences_column`.

### When one page renders multiple editors

The current bundled partial already generates unique preset select/name ids per render, so you can place more than one `table_preferences_editor` on the same page without passing an extra helper keyword.

```erb
<%= table_preferences_editor(
  table_key: :orders,
  name: "default",
  columns: @table_columns,
  title: "画面内の設定"
) %>

<%= table_preferences_editor(
  table_key: :orders,
  name: "default",
  columns: @table_columns,
  title: "ダイアログ内の設定"
) %>
```

Use this rule of thumb:

- Keep `table_key` stable per logical screen or table contract.
- The default bundled partial creates a distinct label/select/name id set for each rendered editor instance automatically.
- When you copy or customize the partial, preserve the label `for` to preset select/name `id` pairing and keep ids unique per rendered instance.
- The current `table_preferences_editor(...)` helper does not expose an explicit `editor_instance_key:` keyword, so avoid passing unsupported options from the host app.

If the host app renders only one editor for the page, you can simply keep the default helper call.

### Applying preferences to an existing HTML table

`table_preferences_table_tag(...)` remains the default path because it emits the controller wiring and target table together. You can still use Rails Table Preferences when the host app already owns the `<table>` markup, for example after Markdown/HTML rewrite, an existing partial, or another server-rendered table builder.

Use this DOM contract:

1. Keep a stable `table_key` per logical screen/template, not per record id or request param.
2. Mount one `rails-table-preferences` controller root per managed table.
3. Put the target `<table>` inside that root, or make the root itself the `<table>`.
4. Add `data-rails-table-preferences-column-key` to each managed `th` / `td`.
5. Leave unmanaged columns without that data attribute.

Minimal table markup example:

```erb
<table class="table">
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="order_no">受注番号</th>
      <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
      <th>備考</th>
    </tr>
  </thead>
  <tbody>
    <% @orders.each do |order| %>
      <tr>
        <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
        <td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
        <td><%= order.note %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

In this example, `order_no` and `customer_name` remain under Rails Table Preferences control, while `備考` stays a normal host-app column.

If you bypass the bundled table helper entirely, the controller root must still receive the same core values as the normal helper output: `tableKey`, `collectionUrl`, `url`, `columns`, and `settings`. See [JavaScript controller notes](javascript_controller.md) for the exact data attributes and controller-side rules.

Users can drag resize handles to change widths. Double-clicking a resize handle auto-fits the column to the currently rendered cells, similar to spreadsheet applications. The resulting width is stored as the normal column `width` setting when the preference is saved.

## 6. Configure overflow behavior when needed

Use `overflow:` to control what happens when text is wider than the configured column width:

```ruby
@table_columns = [
  table_preferences_column(:customer_name, label: "得意先名", default_width: 200, overflow: :ellipsis),
  table_preferences_column(:note, label: "備考", default_width: 320, overflow: :wrap),
  table_preferences_column(:code, label: "コード", default_width: 120, overflow: :clip)
]
```

Supported values:

- `:ellipsis` or `:truncate`: single-line hidden overflow with `...`
- `:clip`: single-line hidden overflow without `...`
- `:wrap`: multi-line wrapping
- `:nowrap`: single-line overflow without clipping

`default_truncate:` remains available as a backward-compatible way to enable ellipsis behavior.

## 7. Add filter and sort metadata when needed

Filters and sorts are saved as UI state. The host application is still responsible for executing database searches.

```ruby
@table_columns = [
  table_preferences_column(
    :customer_name,
    label: "得意先名",
    filter: { type: :text, param: :search_word },
    sortable: true,
    default_width: 240,
    overflow: :ellipsis
  ),
  table_preferences_column(
    :delivery_date,
    label: "納品日",
    filter: { type: :date, from_param: :from_date, to_param: :to_date },
    sortable: true,
    default_width: 140
  )
]
```

Controller integration example:

```ruby
preference_params = rails_table_preference_params(
  table_key: :orders,
  columns: @table_columns
)

merged_params = params.to_unsafe_h.merge(preference_params)

@orders = Order
  .search(merged_params)
  .order_by(merged_params["sort"] || params[:sort])
```

Existing search form integration example:

```erb
<%= table_preferences_hidden_fields(
  settings: @table_preference_settings,
  columns: @table_columns
) %>
```

## 8. Hide columns from the preference UI

Use `ignored: true` for columns that should not appear in the user-facing editor:

```ruby
table_preferences_column(:internal_cost, label: "Internal Cost", ignored: true)
```

Or pass a blacklist when rendering:

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: @table_columns,
  ignored_columns: [:internal_cost]
) %>
```

Columns whose labels cannot be resolved are also treated as ignored by default.

Ignored columns are removed from Rails Table Preferences settings, but the host application must also avoid rendering sensitive data in HTML.

## Next steps

- See [Practical examples](examples.md) for more realistic list-screen integrations.
- See [Controller integration](controller_integration.md) for saved filter/sort params.
- See [Troubleshooting](troubleshooting.md) if the editor, API, CSS, or JavaScript does not behave as expected.
