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

### Empty-state copy

Use `empty_message:` when a screen needs resource-table-specific copy for the records-empty state:

```erb
<%= resource_table_for @orders, empty_message: "No orders yet" %>
<%= tree_resource_table_for @projects, empty_message: "No projects yet" %>
```

Both flat and tree resource table defaults use the custom message only when the record collection is empty. When no custom message is provided, they keep the `rails_table_preferences.resource_table.empty` fallback. The all-columns-hidden message remains separate, so hiding every visible column still uses `rails_table_preferences.resource_table.all_columns_hidden` instead of the records-empty copy.

## Optional filtering of inferred columns

```erb
<%= resource_table_for @orders, except: %i[internal_memo deleted_at] %>
<%= resource_table_for @orders, only: %i[order_no customer_id status delivery_date] %>
<%= resource_table_for @orders, include_id: true %>
```

### Association columns

By default, `resource_table_for` also infers `belongs_to` associations whose foreign key is present on the model. For example, an `Order` with `belongs_to :customer` and a `customer_id` attribute can receive an inferred `customer` column in addition to the attribute columns.

The association column reads through the association reader. Without a profile formatter, that means Rails Table Preferences passes the associated object through the default value fallback rather than deciding how a customer should be labeled, linked, redacted, or preloaded.

Use profile overrides when the screen needs a human-facing association value:

```ruby
class OrdersTableProfile < RailsTablePreferences::TableProfile
  model Order

  order :order_no, :customer, :status, :delivery_date
  label :customer, "Customer"

  display :customer do |order, view|
    next unless order.customer

    view.link_to order.customer.name, view.customer_path(order.customer)
  end
end
```

Choose the column key by the behavior the host app wants:

- use the association key, such as `customer`, when the table should present the associated record and the profile owns the label/link/badge/redaction formatter
- use the foreign key attribute, such as `customer_id`, when the raw stored id is intentionally part of the operator workflow
- use `include_associations: false` when the page wants attribute-only inference, avoids association readers for that table, or will add explicit virtual/profile columns instead

```erb
<%= resource_table_for @orders, include_associations: false %>
```

Rails Table Preferences does not infer joins, eager loading, authorization policy, or business-specific association labels. Keep those decisions in the host application and avoid documenting a formatter as authorization-aware unless the formatter actually performs that check.

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

### Horizontal scroll wrapper

`resource_table_for` can render a small opt-in wrapper around only the table when a convention-first screen needs a basic horizontal overflow container:

```erb
<%= resource_table_for(
  @orders,
  scroll_wrapper: true,
  wrapper_options: {
    class: "orders-table-scroll",
    data: { role: "resource-table-scroll" },
    aria: { label: "Scrollable orders table" }
  },
  class: "orders-table"
) %>
```

`scroll_wrapper:` defaults to `false`, so existing markup stays unchanged until the screen asks for the wrapper. Table HTML options such as `id`, `class`, `data`, and `aria` still belong to the `<table>`. `wrapper_options:` belongs only to the surrounding `<div>` and its class is appended to the default `rails-table-preferences-resource-table-scroll` class.

Use this option for simple `overflow-x: auto` containers or design-system hooks around the flat resource table. More involved sticky columns, scroll shadows, multiple scroll containers, grouped headers, and host-app visual polish remain the host application's responsibility. The generated demo's `.rails-table-preferences-demo-scroll` wrapper is demo-specific; this helper option is the resource table entrypoint for application screens.

`tree_resource_table_for` does not receive this option yet. If a tree table needs a wrapper, keep it in host markup or a custom partial until the tree path is planned separately.

### Captions

Pass `caption:` when the default resource table partial should render a semantic table caption without copying the partial:

```erb
<%= resource_table_for @orders, caption: "Orders" %>
<%= tree_resource_table_for @projects, caption: "Projects" %>
```

The caption is rendered only when present, directly under `<table>` and before `<thead>`. It is not forwarded as a table HTML attribute, so `id`, `class`, `data`, `aria`, and `render_editor` options keep the same pass-through behavior.

Use `caption:` for a short semantic table name. The host app still owns page headings, explanatory copy, complex table semantics, and any custom partial layout beyond the bundled default markup.

## Editor placement

By default, `resource_table_for` and `tree_resource_table_for` render the bundled table preferences editor immediately before the table surface. Use `render_editor: false` when the screen wants to place the editor in a toolbar, drawer, tab, or separate partial while keeping the default table partial.

```erb
<%= table_preferences_editor(
  table_key: :orders,
  settings: @table_preference_settings,
  columns: @preference_columns
) %>

<%= resource_table_for(
  @orders,
  profile: OrdersTableProfile,
  table_key: :orders,
  settings: @table_preference_settings,
  render_editor: false
) %>
```

The opt-out only controls the default editor placement. The table still receives the same settings, columns, table state, HTML options, and Rails Table Preferences data attributes. `tree_resource_table_for` accepts the same option. If the table markup itself needs to change, use a custom partial instead of overloading `render_editor:`.

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

### Formatter argument contract

Profile formatters declared with `display`, `cell`, or `column(..., &block)` use the same value resolver call contract:

- one argument receives the row record
- two arguments receive the row record and view context
- three or more arguments receive the row record, normalized column metadata, and view context

See [Resource table formatter contract](resource_table_formatter_contract.md) for examples and the nil-return / fallback boundary. Formatter code remains presentation-only; the host app still owns eager loading, authorization-aware redaction, and business-specific fallbacks.

### Default value formatting

When a column does not provide a `display` formatter, the bundled value resolver reads the Active Record attribute, association reader, or zero-arity public reader for that column key and then applies a small display fallback.

The fallback is intentionally narrow:

- `nil` renders as an empty string.
- Active Record enum attributes use `#{key}_i18n` when the record exposes it; otherwise the raw value is shown.
- Boolean attributes use `rails_table_preferences.boolean.true` or `rails_table_preferences.boolean.false`, with `Yes` / `No` as the default English fallback.
- Time-like values use the view context `l(...)` helper when it is available; if localization cannot handle the value, the original value is shown.

Use this fallback for simple resource tables where the model value is already safe to show. Add a `display` formatter when the screen needs links, badges, association preloading, authorization-aware redaction, business-specific copy, or export/display divergence. The host app still owns those policies; Rails Table Preferences only provides the compact default presentation path.

### Virtual and computed columns

A profile can also add a small virtual column that is not present in the inferred Active Record columns. Use this for values the record can expose through a public reader or a `display` formatter, such as a customer name, calculated status, or external summary.

```ruby
class OrdersTableProfile < RailsTablePreferences::TableProfile
  model Order

  order :order_no, :customer_name, :status

  column :customer_name,
         label: "Customer",
         filter: { type: "text", param: "customer_name" },
         sortable: false do |order, view|
    view.link_to order.customer.name, view.customer_path(order.customer)
  end
end
```

Virtual columns use the same metadata shape as inferred columns for labels, filters, editors, display formatters, visibility, width, truncate, overflow, pinned state, and sortable metadata. They are appended after inferred columns unless `order` places them elsewhere.

`only` and `exclude` apply to virtual columns too:

- when `only` is empty, profile-defined virtual columns are included unless excluded
- when `only` is present, a virtual column is included only if its key appears in `only`
- `exclude` removes a virtual column even if it was defined with `column`

Rails Table Preferences does not infer joins, eager loading, query execution, or authorization for virtual columns. The host app still owns the relation, any preloading needed by the formatter, and any search/sort behavior behind a virtual filter or sort param.

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
<%= table_preferences_cell_editor(form: form, record: order, column: column) %>
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

## Cross-gem metadata boundary

Use Rails Table Preferences metadata as the table-column contract, not as a shared domain model for every gem on the page. That keeps TreeView, Rails Fields Kit, and host-app query code from depending on each other's private state.

| Area | Stable owner | What crosses the boundary |
| --- | --- | --- |
| Column identity | Rails Table Preferences | `column["key"]`, label, visibility, order, width, overflow, filter, sort, editor, and formatter metadata |
| Tree row identity | TreeView / host app | record id, parent id, node key, hierarchy, expansion, selection, lazy-loading, and row-level hooks |
| Form control rendering | Rails Fields Kit | concrete `rfk_*` helper HTML, Tom Select behavior, selected/lookup URLs, and field-level metadata objects |
| Query and permissions | host app | authorization, relation scope, preloading, search params, sorting, pagination, export params, and business actions |

Do not treat a Rails Table Preferences column key as a TreeView node key. A column key such as `customer_id`, `status`, or `customer_name` identifies one visible table field and the saved display/filter/sort state for that field. A TreeView row or node key identifies a record or hierarchy node. They may both derive from the same Active Record model, but they serve different contracts and should be mapped explicitly in the host app or custom partial.

Likewise, filter and editor metadata can carry Rails Fields Kit objects or renderer types, but Rails Table Preferences only stores that metadata and dispatches to the registered renderer. Rails Fields Kit renders the input; the host app decides which query params are accepted, which records are visible, and which preload or authorization rules apply.

For cross-gem adoption guides or docs-portal matrices, document the smallest explicit mapping: which Rails Table Preferences column key is displayed, which TreeView record or node identity owns the row, which Rails Fields Kit helper renders the control, and which controller/search object consumes the submitted params.

## TreeView integration

When the `tree_view` gem is installed, a tree table can use the same inferred column set:

```erb
<%= tree_resource_table_for @projects, parent_id_method: :parent_project_id %>
```

The bundled default tree table partial expects `TreeView::Tree` to be available. If the host app calls `tree_resource_table_for` without loading the `tree_view` gem, the default partial raises `tree_resource_table_for requires the tree_view gem` instead of silently falling back to flat rows.

Keep `tree_view` in the host app Gemfile when using `tree_resource_table_for`. If the screen should remain usable without TreeView, choose `resource_table_for` for the flat table path or provide a custom `tree_resource_table_partial` that owns that fallback explicitly.

Rails Table Preferences owns the inferred columns, labels, saved table state, and default table partial. TreeView owns the hierarchical row rendering. The host app owns hierarchy query shape, authorization, eager loading, and whether a flat fallback is acceptable for that screen.

## Custom presentation

The bundled partials are defaults, not the extension protocol. Applications that need different markup can configure partials:

```ruby
RailsTablePreferences.configure do |config|
  config.resource_table_partial = "shared/tables/resource_table"
  config.tree_resource_table_partial = "shared/tables/tree_resource_table"
end
```

Custom partials receive `records`, `model`, `table_key`, `name`, `settings`, `columns`, `table_state`, `profile`, `caption`, `options`, `scroll_wrapper`, and `wrapper_options`.

Use `table_preferences_value(record, column)` when the default value resolver is enough, or provide a profile override with `display`.