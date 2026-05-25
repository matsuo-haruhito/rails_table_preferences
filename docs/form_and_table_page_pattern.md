# Management page pattern: create form + editor + table

This guide shows a common admin screen composition where a create form, the Rails Table Preferences editor, and the list table live on the same page.

It is a good fit for master-data or back-office screens where users often create one record, then immediately review or adjust the list below.

## When this pattern fits

Use this pattern when the screen needs all of the following:

- a normal Rails form for creating or updating records
- a list table that benefits from saved columns, widths, filters, sorts, or presets
- a page flow where users stay on the same screen after creating a record

Typical examples include customer masters, inventory lists, document sets, or other admin indexes where the page is both an input surface and a review surface.

## Minimal page composition

Keep the responsibilities separate even when the UI is on one page:

1. the form creates or updates records
2. the table preference editor manages saved display state
3. the list query renders records according to normal host-app search and ordering rules

A minimal ERB layout looks like this:

```erb
<% table_key = :admin_orders %>
<% table_columns = order_table_columns %>
<% table_settings = rails_table_preference_settings(table_key: table_key) %>

<section>
  <h2>New order</h2>
  <%= render "form", order: @order %>
</section>

<section>
  <%= table_preferences_editor(
    table_key: table_key,
    settings: table_settings,
    columns: table_columns,
    title: "Order list settings"
  ) %>
</section>

<%= table_preferences_table_tag(
  table_key: table_key,
  settings: table_settings,
  columns: table_columns,
  class: "table"
) do %>
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="order_no">Order No.</th>
      <th data-rails-table-preferences-column-key="customer_name">Customer</th>
      <th data-rails-table-preferences-column-key="status">Status</th>
      <th data-rails-table-preferences-column-key="actions">Actions</th>
    </tr>
  </thead>
  <tbody>
    <% @orders.each do |order| %>
      <tr>
        <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
        <td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
        <td data-rails-table-preferences-column-key="status"><%= order.status %></td>
        <td data-rails-table-preferences-column-key="actions">
          <%= link_to "Edit", edit_order_path(order) %>
        </td>
      </tr>
    <% end %>
  </tbody>
<% end %>
```

The screen can place the form above the editor, the editor above the table, or the form and editor in separate cards or sections. The important part is not the exact visual layout. The important part is that all three areas share one stable `table_key` and one column definition set for the list itself.

## Responsibility split

### Form side

The form still owns:

- create and update requests
- validations and error display
- authorization for record changes
- any redirect or re-render behavior after submit

Rails Table Preferences should not be used as the save mechanism for the record form itself.

### Table preference side

The editor owns:

- visible columns
- column order and width
- overflow or truncation preferences
- saved filters and sorts as UI state
- personal or scoped presets, depending on host-app configuration

The editor saves display preferences, not business records.

### List query side

The host app still owns:

- query execution
- joins and includes
- pagination
- business-specific sorting rules
- deciding whether saved filter or sort state should feed the current query

If the list should follow saved filter or sort state, merge the resolved params in the controller:

```ruby
preference_params = rails_table_preference_params(
  table_key: :admin_orders,
  columns: order_table_columns
)

merged_params = params.to_unsafe_h.merge(preference_params)

@orders = Order.search(merged_params).order_by(merged_params["sort"] || params[:sort])
```

The create form submission and the table query do not need to share the same params contract. Keep them separate unless the host app already has a good reason to combine them.

## Controller shape

A common controller shape is:

```ruby
class Admin::OrdersController < ApplicationController
  def index
    @order = Order.new
    @table_columns = order_table_columns

    preference_params = rails_table_preference_params(
      table_key: :admin_orders,
      columns: @table_columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    @orders = Order.search(merged_params)
                   .order_by(merged_params["sort"] || params[:sort])
  end

  def create
    @order = Order.new(order_params)

    if @order.save
      redirect_to admin_orders_path, notice: "Created"
    else
      @table_columns = order_table_columns
      preference_params = rails_table_preference_params(
        table_key: :admin_orders,
        columns: @table_columns
      )
      merged_params = params.to_unsafe_h.merge(preference_params)
      @orders = Order.search(merged_params)
                     .order_by(merged_params["sort"] || params[:sort])
      render :index, status: :unprocessable_entity
    end
  end
end
```

The important recovery path is the failed `create` case. If the page re-renders `index`, rebuild the same column metadata and list data so the table and editor still have the context they expect.

## Good first slice for an existing admin screen

When adding Rails Table Preferences to an already-working management screen, the lowest-risk order is:

1. keep the existing form and list query behavior unchanged
2. define one stable `table_key` for the list screen
3. define one shared column array for the editor and table
4. wrap the existing table with `table_preferences_table_tag`
5. render `table_preferences_editor` next to that table
6. only after that, decide whether profile classes, hidden fields, renderer registries, or deeper helper integration are useful

This keeps the first slice focused on display preferences instead of rewriting the whole page architecture.

## Resource-table variant

If the screen already fits the convention-first helper path, the same composition works with `resource_table_for`.

Example shape:

```erb
<section>
  <h2>New order</h2>
  <%= render "form", order: @order %>
</section>

<section>
  <%= table_preferences_editor(
    table_key: :admin_orders,
    columns: RailsTablePreferences.columns_for(Order)
  ) %>
</section>

<%= resource_table_for @orders, table_key: :admin_orders %>
```

Use this only when the inferred or profile-driven table is already close to what the screen needs. If the page has many custom cells, actions, or grouped headers, a hand-written table may stay clearer.

## What not to mix into the first docs slice

To keep this pattern portable across host apps, avoid turning the first example into:

- a full design-system prescription
- a renderer-registry deep dive
- a search-API redesign
- an inline-editing framework
- a full admin preset management UI

Those can be added later if a project needs them. The first goal is simply to show that create form, editor, and table can coexist without sharing the same save responsibility.

## Related guides

- [Quick start](quick_start.md)
- [Resource table adapters](resource_tables.md)
- [Controller integration](controller_integration.md)
- [Practical examples](examples.md)
