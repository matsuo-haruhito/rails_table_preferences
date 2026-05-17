# Resource table adapters

Resource table helpers provide a convention-first path for Rails applications that do not want to define every table column by hand.

They infer user-facing columns from an Active Record model, then reuse the existing Rails Table Preferences label resolution rules.

## Basic table

```erb
<%= resource_table_for @orders %>
```

`resource_table_for` infers the model from `records.klass` when possible. It builds column definitions from `model.attribute_names`, passes each column through `RailsTablePreferences::ColumnDefinition`, and hides columns whose labels cannot be resolved when `unresolved_label_behavior = :hide`.

That means host applications can expose table columns by using one of the configured label sources, for example:

- `label:` in an explicit column-like object
- `i18n_key:`
- database column comments
- Rails attribute translations when configured

## Optional filtering of inferred columns

```erb
<%= resource_table_for @orders, except: %i[internal_memo deleted_at] %>
<%= resource_table_for @orders, only: %i[order_no customer_id status delivery_date] %>
<%= resource_table_for @orders, include_id: true %>
```

The helpers are intentionally override-light. Use `only:`, `except:`, and label-resolution configuration before introducing custom per-table code.

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

Custom partials receive:

- `records`
- `model`
- `table_key`
- `name`
- `settings`
- `columns`
- `table_state`
- `options`

Use `table_preferences_value(record, column)` when the default value resolver is enough, or provide a column-like object that exposes `to_table_preference_column` with a callable `formatter` or `cell` value.
