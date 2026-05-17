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
