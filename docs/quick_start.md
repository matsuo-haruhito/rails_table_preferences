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
  table_preferences_column(:customer_name, label: "得意先名", default_width: 240, default_truncate: 30),
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
  table_preferences_column(:customer_name, model: Order, default_width: 240, default_truncate: 30),
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

## 6. Add filter and sort metadata when needed

Filters and sorts are saved as UI state. The host application is still responsible for executing database searches.

```ruby
@table_columns = [
  table_preferences_column(
    :customer_name,
    label: "得意先名",
    filter: { type: :text, param: :search_word },
    sortable: true,
    default_width: 240
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

## 7. Hide columns from the preference UI

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