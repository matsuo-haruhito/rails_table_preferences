# Resource table adapters

Resource table helpers provide a convention-first path for Rails applications that do not want to define every table column by hand.

They infer user-facing columns from an Active Record model, then reuse the existing Rails Table Preferences label resolution rules.

## Basic table

```erb
<%= resource_table_for @orders %>
```

`resource_table_for` infers the model from `records.klass` when possible. It builds column definitions from `model.attribute_names`, passes each column through `RailsTablePreferences::ColumnDefinition`, and hides columns whose labels cannot be resolved when `unresolved_label_behavior = :hide`.

### Model inference and empty collections

Relation-like collections are the most convenient path because `records.klass` tells the helper which Active Record model to inspect:

```erb
<%= resource_table_for Order.where(status: "open") %>
```

Plain arrays can still work when they contain at least one record, because the helper can fall back to the first record's class:

```erb
<%= resource_table_for @orders.to_a %>
```

When records do not expose `klass` and may be empty, pass the model explicitly or put the model on the profile. This is the safe path for empty arrays, manually assembled collections, and pages that intentionally render before a query has returned rows.

```erb
<%= resource_table_for [], model: Order %>
<%= resource_table_for @orders, profile: OrdersTableProfile %>
```

```ruby
class OrdersTableProfile < RailsTablePreferences::TableProfile
  model Order
end
```

If neither `model:` nor profile `model` is available and the collection has no `klass` or first record, the helper raises `model: is required when records do not expose klass and are empty` instead of guessing.

If the same management page also includes a search form, pagination, a create form, or other host-app actions, keep those as separate responsibilities around the table. See [Practical examples](examples.md) for copyable page-composition examples, including a convention-first list screen with small profile overrides and a create-form-plus-list screen.

## Optional filtering of inferred columns

```erb
<%= resource_table_for @orders, except: %i[internal_memo deleted_at] %>
<%= resource_table_for @orders, only: %i[order_no customer_id status delivery_date] %>
<%= resource_table_for @orders, include_id: true %>
```

## Table HTML options

The default resource table partials pass basic table HTML options through to `table_preferences_table_tag` while preserving the gem-owned controller data attributes.

```erb
<%= resource_table_for(
  @orders,
  id: "orders-table",
  class: "orders-table",
  data: { turbo_frame: "orders-frame" },
  aria: { label: "Orders" }
) %>
```

`class:` is appended to the default resource table class instead of replacing it. Generic `data:` attributes can coexist with the Rails Table Preferences controller data, but the gem-owned `data-rails-table-preferences-*` values remain authoritative.

`tree_resource_table_for` follows the same pass-through rule and keeps its default `tree-view-table` and `rails-table-preferences-tree-resource-table` classes.

## Profile overrides

Use a profile when the inferred table is mostly right, but a screen needs small overrides.

```ruby
class OrdersTableProfile < RailsTablePreferences::TableProfile
  model Order

  exclude :internal_memo, :deleted_at
  order :order_no, :customer_id, :status, :delivery_date
  label :customer_id, "Customer"

  display :customer_id do |order, view|
    view.link_to order.customer.name, view.customer_path(order.customer)
  end

  filter :customer_id, type: "association", association: "customer", foreign_key: "customer_id"
end
```

```erb
<%= resource_table_for @orders, profile: OrdersTableProfile %>
```

Profiles are applied after Active Record column inference. They are for deltas, not full table definitions.

Supported profile directives include `model`, `only`, `exclude`, `order`, `label`, `filter`, `editor`, `display`, and `column`.

## Round-trip saved filter/sort params through an existing search form

Use this pattern when the page wants `resource_table_for` for the visible table surface, but the surrounding search form should still round-trip saved filter/sort UI state.

Controller:

```ruby
class OrdersController < ApplicationController
  def index
    @preference_columns = [
      table_preferences_column(
        :customer_id,
        label: "Customer",
        filter: { type: :text, param: :customer_id }
      ),
      table_preferences_column(
        :status,
        label: "Status",
        filter: { type: :text, param: :status },
        sortable: true
      ),
      table_preferences_column(
        :delivery_date,
        label: "Delivery date",
        filter: { type: :date, from_param: :from_delivery_date, to_param: :to_delivery_date },
        sortable: true
      )
    ]

    @table_preference_settings = rails_table_preference_settings(
      table_key: :orders,
      name: params[:table_preference_name]
    )

    preference_params = rails_table_preference_params(
      table_key: :orders,
      name: params[:table_preference_name],
      columns: @preference_columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    @orders = Order
      .includes(:customer)
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])
      .page(params[:page])
  end
end
```

View:

```erb
<%= form_with url: orders_path, method: :get do %>
  <%= text_field_tag :customer_id, params[:customer_id], placeholder: "Customer" %>
  <%= text_field_tag :status, params[:status], placeholder: "Status" %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] if params[:table_preference_name].present? %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @preference_columns
  ) %>

  <%= submit_tag "Search" %>
<% end %>

<%= resource_table_for @orders, profile: OrdersTableProfile, table_key: :orders %>
```

`rails_table_preference_params(...)` converts saved filter/sort UI state into the query params the controller can merge into the existing search call. `rails_table_preference_settings(...)` keeps the normalized saved settings available for the view so `table_preferences_hidden_fields(...)` can submit the same state with the next search form request.

Why this split works:

- `resource_table_for` still owns inferred columns, profile overrides, and the rendered table surface
- `rails_table_preference_params(...)` and `table_preferences_hidden_fields(...)` only describe how saved filter/sort UI state maps back into the existing controller/search form contract
- the host app still owns query execution, pagination, and deciding which params are safe to send through the search form

This keeps the resource-table path convention-first while making the params boundary explicit. When the screen later adds export actions, keep the export submit separate and pass only the query params that export should accept. See [Export integration](export_integration.md) for that adjacent pattern.

## Renderer registries

Renderer registries convert filter/editor metadata into HTML without making Rails Table Preferences depend on a specific form helper library.

```ruby
RailsTablePreferences.configure do |config|
  config.filter_renderers.register("rails_fields_kit") do |form:, method:, filter:, **|
    form.rfk_combobox(method, **filter.fetch("options", {}).symbolize_keys)
  end

  config.editor_renderers.register("rails_fields_kit") do |form:, method:, editor:, **|
    form.rfk_combobox(method, **editor.fetch("options", {}).symbolize_keys)
  end
end
```

Custom partials can then call:

```erb
<%= table_preferences_filter_input(form: form, column: column) %>
<%= table_preferences_cell_editor(form: form, record: record, column: column) %>
```

When a column has no filter/editor metadata, or when the metadata type has no registered renderer, the helper returns the `fallback:` value. Use that to keep custom partials explicit about the empty state they want:

```erb
<%= table_preferences_filter_input(
  form: form,
  column: column,
  fallback: "".html_safe
) %>

<%= table_preferences_cell_editor(
  form: form,
  record: order,
  column: column,
  fallback: table_preferences_value(order, column)
) %>
```

Choose an empty fallback when an unsupported filter/editor should render nothing, or a plain value fallback when the table should remain readable without an editor renderer. Registering a renderer is still the host app's responsibility; Rails Table Preferences only looks up the type and calls the registered mapping.

A column filter or editor may also be an object that responds to `to_table_filter` or `to_table_cell_editor`.

## Rails Fields Kit end-to-end example

When the host app wants Rails Table Preferences to describe filter/editor metadata and Rails Fields Kit to render the actual controls, keep the flow in three steps:

1. declare table column metadata
2. register renderer mappings
3. call the renderer helpers from the table partial

### 1. Declare metadata in the table profile

```ruby
class OrdersTableProfile < RailsTablePreferences::TableProfile
  model Order

  column :customer_id,
         label: "Customer",
         filter: RailsFieldsKit::TableFilterInput.combobox(
           :customer_id,
           url: "/customers.json",
           selected_url: "/customers/selected.json",
           value_field: "id",
           label_field: "name"
         )

  column :status,
         label: "Status",
         editor: RailsFieldsKit::TableCellInput.enum_select(:status)
end
```

The important part is that the profile stores metadata objects such as `RailsFieldsKit::TableFilterInput.combobox(...)` and `RailsFieldsKit::TableCellInput.enum_select(...)`. Rails Table Preferences keeps those objects as column metadata; it does not render the HTML yet.

### 2. Register renderer mappings in the host app

```ruby
RailsTablePreferences.configure do |config|
  config.filter_renderers.register("rails_fields_kit") do |form:, method:, filter:, **|
    form.rfk_combobox(method, **filter.fetch("options", {}).symbolize_keys)
  end

  config.editor_renderers.register("rails_fields_kit") do |form:, method:, editor:, **|
    form.rfk_enum_select(method, **editor.fetch("options", {}).symbolize_keys)
  end
end
```

If the metadata uses a different Rails Fields Kit field type, map that type to the matching `rfk_*` helper here.

### 3. Render from the table partial

```erb
<% columns.each do |column| %>
  <th>
    <%= column["label"] %>
    <%= table_preferences_filter_input(form: form, column: column) %>
  </th>
<% end %>

<% @orders.each do |order| %>
  <tr>
    <% columns.each do |column| %>
      <td>
        <%= table_preferences_value(order, column) %>
        <%= table_preferences_cell_editor(form: form, record: order, column: column) %>
      </td>
    <% end %>
  </tr>
<% end %>
```

`table_preferences_filter_input` and `table_preferences_cell_editor` read the column metadata, pick the registered renderer, and call the matching Rails Fields Kit helper.

### Responsibility split

- Rails Table Preferences owns column metadata, saved table state, partial helper entrypoints, and renderer registry lookup.
- Rails Fields Kit owns the concrete form helper HTML and Stimulus/Tom Select behavior behind `rfk_*` helpers.
- The host app owns the final partial layout, route URLs, and any controller/query behavior behind the rendered inputs.

This split keeps the table gem independent from a specific form helper library while still giving the host app a copyable end-to-end path.

## TreeView integration

When the `tree_view` gem is installed, a tree table can use the same inferred column set:

```erb
<%= tree_resource_table_for @projects, parent_id_method: :parent_project_id %>
```

Rails Table Preferences owns the inferred columns, labels, saved table state, and default table partial. TreeView owns the hierarchical row rendering.

## Custom presentation

The bundled partials are defaults, not the extension protocol. Applications that need different markup can configure partials:

```ruby
RailsTablePreferences.configure do |config|
  config.resource_table_partial = "shared/tables/resource_table"
  config.tree_resource_table_partial = "shared/tables/tree_resource_table"
end
```

Custom partials receive `records`, `model`, `table_key`, `name`, `settings`, `columns`, `table_state`, `profile`, and `options`.

Use `table_preferences_value(record, column)` when the default value resolver is enough, or provide a profile override with `display`.
