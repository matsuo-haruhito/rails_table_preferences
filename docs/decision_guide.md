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
  table_preferences_column(:order_no, label: "受注番号", default_width: 120),
  table_preferences_column(:customer_name, label: "得意先名", default_width: 240)
]
```

You can also use database column comments by passing an Active Record model class:

```ruby
columns = [
  table_preferences_column(:order_no, model: Order, default_width: 120),
  table_preferences_column(:customer_name, model: Order, default_width: 240)
]
```

By default, columns whose labels cannot be resolved are treated as ignored and do not appear in the editor.

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

Users can drag resize handles to change widths. They can also double-click a resize handle to auto-fit the column to the currently rendered cells. Auto-fit writes the result back as the normal column `width`, so the value is saved with the preset.

## I want long text to be clipped, wrapped, or ellipsized

Use `overflow:` on the column definition.

```ruby
columns = [
  table_preferences_column(:customer_name, label: "得意先名", default_width: 200, overflow: :ellipsis),
  table_preferences_column(:note, label: "備考", default_width: 320, overflow: :wrap),
  table_preferences_column(:code, label: "コード", default_width: 120, overflow: :clip)
]
```

Supported values:

- `:ellipsis` or `:truncate`: keep one line, hide overflow, and show `...`
- `:clip`: keep one line and hide overflow without `...`
- `:wrap`: allow multiple lines
- `:nowrap`: keep one line without clipping

`default_truncate:` still enables ellipsis behavior for backward compatibility, but `overflow:` is clearer for new screens.

## I want fixed or pinned columns

Use `fixed: true` or `pinned: true` on the column definition.

```ruby
columns = [
  table_preferences_column(:order_no, label: "受注番号", fixed: true, default_width: 120),
  table_preferences_column(:customer_name, label: "得意先名", default_width: 240)
]
```

`fixed:` is an alias for `pinned:`. The default stylesheet provides sticky-column CSS hooks, but the host app owns final scroll-container and offset polish.

See [Fixed columns and column groups](fixed_columns_and_groups.md).

## I want grouped table headers or grouped export headers

Use `group:` metadata and `table_preferences_column_groups`.

```ruby
columns = [
  table_preferences_column(:customer_code, label: "得意先コード", group: { key: :customer, label: "得意先情報" }),
  table_preferences_column(:customer_name, label: "得意先名", group: { key: :customer, label: "得意先情報" }),
  table_preferences_column(:delivery_date, label: "納品日", group: { key: :delivery, label: "配送情報" })
]
```

```erb
<thead>
  <tr>
    <% table_preferences_column_groups(columns).each do |group| %>
      <th colspan="<%= group["colspan"] %>"><%= group["label"] %></th>
    <% end %>
  </tr>
  <tr>
    <% table_preferences_columns(columns).each do |column| %>
      <th data-rails-table-preferences-column-key="<%= column["key"] %>"><%= column["label"] %></th>
    <% end %>
  </tr>
</thead>
```

Column groups are metadata. Rails Table Preferences helps normalize and group them, but the host app owns the final table header markup.

See [Fixed columns and column groups](fixed_columns_and_groups.md).

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

## I want shared, role, or organization default presets

Use scoped presets.

Configure a scope context method only when the application needs shared, role, or organization preset resolution:

```ruby
RailsTablePreferences.configure do |config|
  config.scope_context_method = :table_preference_scope_context
end
```

```ruby
class ApplicationController < ActionController::Base
  private

  def table_preference_scope_context
    {
      roles: current_user.roles.pluck(:key),
      organization: current_user.organization_id
    }
  end
end
```

Default resolution priority is owner, role, organization, shared, then owner `default` fallback.

See [Scoped presets](scoped_presets.md).

## I want users to hide columns, but some columns must never appear in the editor

Use `ignored: true`, `ignore: true`, or `ignored_columns:`.

Per-column form:

```ruby
columns = [
  table_preferences_column(:customer_name, label: "得意先名"),
  table_preferences_column(:internal_cost, label: "内部原価", ignored: true)
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

Use explicit labels, explicit i18n keys, or database column comments. The default label resolution order is:

1. `label:`
2. `i18n_key:`
3. `model.columns_hash[key].comment` when `model:` is an Active Record model class

```ruby
table_preferences_column(:customer_name, label: "得意先名")
table_preferences_column(:delivery_date, i18n_key: "orders.index.columns.delivery_date")
table_preferences_column(:customer_code, model: Order)
```

Host apps that want Rails-style attribute translations can add those rules in the initializer:

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
        customer_name: 得意先名
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
  label: "得意先名",
  filter: { type: :text, param: :search_word },
  sortable: true,
  overflow: :ellipsis
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
  label: "状態",
  filter: { type: :select, param: :status, options: ["未出荷", "出荷済"] }
)
```

The UI state can be saved and restored without affecting the database results until the host application chooses to apply the adapter params.

## I want sortable headers

Set `sortable: true` on the column.

```ruby
table_preferences_column(:delivery_date, label: "納品日", sortable: true)
```

Use `sort_param:` when the display column key differs from the host application's sort key:

```ruby
table_preferences_column(:delivery_date, label: "納品日", sortable: true, sort_param: :delivery_on)
```

Header click cycles through ascending, descending, and no sort. The host application must apply the resulting sort param.

## I want exports to follow saved column settings

Use `rails_table_preference_export_payload` in the controller.

```ruby
payload = rails_table_preference_export_payload(
  table_key: :orders,
  columns: columns,
  name: params[:table_preference_name]
)
```

The payload gives the host app ordered columns, column keys, headers, and metadata. Rails Table Preferences does not generate the CSV or Excel file.

See [Export integration](export_integration.md).

## I want resource table filters or cell editors to use my form helper library

Start with the standard resource table helpers when display-only inferred columns are enough. Add renderer registries when the column metadata should stay in the profile but the actual filter input or cell editor HTML should come from a host-app form helper library, such as Rails Fields Kit.

Use a custom partial only when the table markup, cell layout, or empty-state behavior needs to change beyond renderer lookup.

In short:

- Standard helper: use `resource_table_for` when inferred columns and default table markup are enough.
- Renderer registry: register `filter_renderers` or `editor_renderers` when metadata should render through host-app helpers.
- Custom partial: copy or configure a partial when the table structure itself needs different markup.

See [Resource table adapters](resource_tables.md#renderer-registries).

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
- export column payloads

The host application owns:

- database query execution
- joins and association logic
- authorization
- pagination
- exports
- business-specific search behavior
