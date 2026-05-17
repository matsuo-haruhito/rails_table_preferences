# Decision guide

Use this guide when you know what you want to do, but are not sure which Rails Table Preferences API or option to use.

Rails Table Preferences is intentionally split into small helpers and adapters. The host application still owns the table markup, database query execution, authorization, and business-specific behavior.

## I want users to show, hide, reorder, and resize table columns

Use:

- `table_preferences_column`
- `table_preferences_editor`
- `table_preferences_table_tag`

Example:

```ruby
columns = [
  table_preferences_column(:order_no, model_name: :order, default_width: 120),
  table_preferences_column(:customer_name, model_name: :order, default_width: 240)
]
```

```erb
<%= table_preferences_editor(table_key: :orders, columns: columns) %>

<%= table_preferences_table_tag(table_key: :orders, columns: columns, class: "table") do %>
  ...
<% end %>
```

Every target table header and cell should use the matching column key:

```erb
<th data-rails-table-preferences-column-key="customer_name">得意先名</th>
<td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
```

## I want to save multiple named presets

Use the bundled editor as-is.

The default editor includes preset selection, preset name, default preset, Apply, Save, Save as new, Delete, and Reset actions.

Use `name:` when the screen should load a specific preset:

```erb
<%= table_preferences_editor(
  table_key: :orders,
  name: params[:table_preference_name] || "default",
  columns: columns
) %>
```

When no `name:` is given, preference lookup uses this order:

1. The preset with `default_flag = true`
2. The preset named `default`
3. Empty normalized settings

## I want users to hide columns, but some columns must never appear in the editor

Use `ignored: true`, `ignore: true`, or `ignored_columns:`.

Per-column form:

```ruby
columns = [
  table_preferences_column(:customer_name, model_name: :order),
  table_preferences_column(:internal_cost, model_name: :order, ignored: true)
]
```

Render-time blacklist:

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: columns,
  ignored_columns: [:internal_cost, :secret_note]
) %>
```

Ignored columns are removed from Rails Table Preferences settings and editor payloads. They are not an authorization mechanism. Do not render sensitive values in the host application's HTML, query, serializer, or API response.

## I want Japanese column labels

Prefer host app locale entries or explicit labels.

Use `model_name:` or `model:` when the label should come from Active Record/Active Model translations:

```ruby
table_preferences_column(:customer_name, model_name: :order)
table_preferences_column(:customer_code, model: Order)
```

Host app locale example:

```yaml
ja:
  activerecord:
    attributes:
      order:
        customer_name: 得意先名
```

Use `label:` when the screen needs a fixed label:

```ruby
table_preferences_column(:customer_name, label: "得意先名")
```

## I want filter and sort UI state, but my controller already has search(params)

Use `rails_table_preference_params` in the controller and merge the result into your existing params.

```ruby
preference_params = rails_table_preference_params(
  table_key: :orders,
  columns: columns
)

merged_params = params.to_unsafe_h.merge(preference_params)

@orders = Order
  .search(merged_params)
  .order_by(merged_params["sort"] || params[:sort])
```

Declare the mapping on each column:

```ruby
table_preferences_column(
  :customer_name,
  filter: { type: :text, param: :search_word },
  sortable: true
)
```

Rails Table Preferences only creates adapter params. The host application still executes the query.

## I want saved filters/sorts to submit through an existing search form

Use `table_preferences_hidden_fields` inside the existing form.

```erb
<%= form_with url: orders_path, method: :get do %>
  <%= text_field_tag :search_word, params[:search_word] %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: columns
  ) %>

  <%= submit_tag "検索" %>
<% end %>
```

This is useful when the host app already expects params from a normal search form.

## I use Ransack

Use `adapter: :ransack`.

Controller example:

```ruby
ransack_params = rails_table_preference_params(
  table_key: :orders,
  columns: columns,
  adapter: :ransack
)

@q = Order.ransack(params.fetch(:q, {}).to_unsafe_h.merge(ransack_params))
@orders = @q.result
```

Existing search form example:

```erb
<%= table_preferences_hidden_fields(
  settings: @table_preference_settings,
  columns: columns,
  adapter: :ransack,
  namespace: :q
) %>
```

## I want filter UI only, not saved database query behavior

Use filter metadata on columns, but do not call `rails_table_preference_params` in the controller.

```ruby
table_preferences_column(
  :status,
  filter: { type: :select, param: :status, options: ["未出荷", "出荷済"] }
)
```

The UI state can be saved and restored without affecting the database results until the host application chooses to apply the adapter params.

## I want sortable headers

Set `sortable: true` on the column.

```ruby
table_preferences_column(:delivery_date, sortable: true)
```

Use `sort_param:` when the display column key differs from the host application's sort key:

```ruby
table_preferences_column(:delivery_date, sortable: true, sort_param: :delivery_on)
```

Header click cycles through ascending, descending, and no sort. The host application must apply the resulting sort param.

## I want to customize the editor markup

Use the views generator:

```bash
bin/rails generate rails_table_preferences:views
```

Then edit:

```text
app/views/rails_table_preferences/_editor.html.erb
```

Or pass a custom partial per call:

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: columns,
  partial: "shared/table_preferences_editor"
) %>
```

## I want to customize CSS

Use the stylesheet generator:

```bash
bin/rails generate rails_table_preferences:stylesheets
```

Then edit:

```text
app/assets/stylesheets/rails_table_preferences.css
```

The default stylesheet is intentionally minimal and copy-based.

## I want to customize JavaScript or register Stimulus myself

Use the default copied controller for the normal path:

```text
app/javascript/controllers/rails_table_preferences_controller.js
```

Skip copying when the host app wants to provide its own controller:

```bash
bin/rails generate rails_table_preferences:install --skip-javascript
```

Then register a Stimulus controller with the same controller name:

```js
application.register("rails-table-preferences", YourController)
```

## I use importmap

Rails Table Preferences does not require importmap-specific setup.

The default install generator copies the Stimulus controller into the host app:

```text
app/javascript/controllers/rails_table_preferences_controller.js
```

For the default `stimulus-rails` manifest loader, files under `app/javascript/controllers/*_controller.js` are usually registered automatically.

If the host app uses a custom Stimulus setup, register the copied controller manually.

## I use jsbundling or a custom frontend setup

Import and register the copied controller manually if automatic registration is not used:

```js
import RailsTablePreferencesController from "./controllers/rails_table_preferences_controller"
application.register("rails-table-preferences", RailsTablePreferencesController)
```

CSS loading is also host-app specific. Import or include the copied stylesheet in the host application's CSS bundle.

## I want to verify the gem before integrating a real screen

Use the demo screen generator:

```bash
bin/rails generate rails_table_preferences:install --with-demo
```

Then add the route described by the generator:

```ruby
get "/rails_table_preferences_demo/orders", to: "rails_table_preferences_demo/orders#index"
```

See [Demo screen generator](demo.md) and [Sandbox Rails app verification](sandbox.md).

## I already have ColumnAdjustment-style saved settings

Use the legacy import rake task:

```bash
bin/rails rails_table_preferences:legacy:import_column_adjustments
```

Run a dry run first:

```bash
DRY_RUN=1 bin/rails rails_table_preferences:legacy:import_column_adjustments
```

The importer reads legacy keys such as `column_name`, `display_flag`, and `display_order`, then stores normalized settings in `table_preferences`.

## I am not sure whether this gem should execute my search query

It should not.

Rails Table Preferences owns:

- display preference UI
- saved column settings
- saved filter/sort UI state
- adapter params for existing host app search code

The host application owns:

- database query execution
- joins and association logic
- authorization
- pagination
- exports
- business-specific search behavior
