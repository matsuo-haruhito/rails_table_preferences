# Resource table adapters

Resource table helpers provide a convention-first path for Rails applications that do not want to define every table column by hand.

They infer user-facing columns from an Active Record model, then reuse the existing Rails Table Preferences label resolution rules.

## Basic table

```erb
<%= resource_table_for @orders %>
```

`resource_table_for` infers the model from `records.klass` when possible. It builds column definitions from `model.attribute_names`, passes each column through `RailsTablePreferences::ColumnDefinition`, and hides columns whose labels cannot be resolved when `unresolved_label_behavior = :hide`.

## Optional filtering of inferred columns

```erb
<%= resource_table_for @orders, except: %i[internal_memo deleted_at] %>
<%= resource_table_for @orders, only: %i[order_no customer_id status delivery_date] %>
<%= resource_table_for @orders, include_id: true %>
```

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

## Management screens with a create form on the same page

A common admin pattern is one page with:

- a create form near the top
- the table preference editor for the list
- the list table itself below

This is still a good fit for resource tables as long as the responsibilities stay separate:

- the form saves business records
- the editor saves display preferences
- the list query still belongs to the host app

For a copyable page shape and controller recovery path, see [Management page pattern: create form + editor + table](form_and_table_page_pattern.md).

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
