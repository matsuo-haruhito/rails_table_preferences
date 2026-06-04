# Virtual column query boundary

Use this guide when a `resource_table_for` profile adds a virtual or computed column that also needs filter or sort metadata.

A virtual column can be a useful display surface, but it does not make Rails Table Preferences a query builder. The gem can carry the column key, label, saved filter UI state, saved sort UI state, and profile formatter. The host application still owns the relation, joins, preloading, allowed params, authorization, and database query execution.

## Example: customer name virtual column

In this example, the table shows a linked customer name even though the `orders` table stores only `customer_id`. The profile exposes `customer_name` as the display/preference key, while the controller maps the submitted params into the host application's existing search and sort code.

```ruby
class OrdersIndexTableProfile < RailsTablePreferences::TableProfile
  model Order

  order :order_no, :customer_name, :status, :delivery_date

  column :customer_name,
         label: "Customer",
         filter: { type: :text, param: :customer_name },
         sortable: true,
         sort_param: :customer_name do |order, view|
    next unless order.customer

    view.link_to order.customer.name, view.customer_path(order.customer)
  end
end
```

```ruby
class OrdersController < ApplicationController
  def index
    @table_profile = OrdersIndexTableProfile

    preference_params = rails_table_preference_params(
      table_key: :orders,
      name: params[:table_preference_name],
      columns: @table_profile.columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    @orders = Order
      .includes(:customer)
      .search(merged_params.slice("customer_name", "status", "from_delivery_date", "to_delivery_date"))
      .order_by(merged_params["sort"] || params[:sort])
      .page(params[:page])
  end
end
```

```erb
<%= form_with url: orders_path, method: :get do %>
  <%= text_field_tag :customer_name, params[:customer_name], placeholder: "Customer" %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] if params[:table_preference_name].present? %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @table_profile.columns
  ) %>

  <%= submit_tag "Search" %>
<% end %>

<%= resource_table_for @orders, profile: @table_profile, table_key: :orders %>
```

## Why the split matters

The virtual column key is `customer_name` because that is the table preference and display concept users see. The formatter reads `order.customer`, so the controller explicitly preloads `:customer` before rendering. Rails Table Preferences does not inspect the formatter and infer `includes(:customer)`.

The saved filter metadata maps to the plain `customer_name` param through `filter: { param: :customer_name }`. The saved sort metadata maps through `sort_param: :customer_name`. Those params are still only inputs to host-app code. The host application decides whether `customer_name` means a SQL join, a search object field, a Ransack predicate, a materialized column, or a rejected/ignored param.

Keep the accepted query params explicit. In the example, `slice(...)` is intentionally narrow so an old saved setting cannot introduce an arbitrary search key.

## Checklist

Before shipping a virtual column with filter or sort metadata, confirm:

- the profile formatter only handles presentation and does not hide authorization or query policy
- the controller relation preloads any associations the formatter reads
- the host app search object or query scope explicitly accepts the filter param
- the host app sort code explicitly accepts the sort value
- unknown or stale saved filter/sort keys are ignored or rejected by host-app code
- exports, if present, use an explicit export key or host-app extraction rule for the same virtual value

Use [Resource table adapters](resource_tables.md) for the profile and formatter contract, [Filter metadata](filter_metadata.md) for neutral filter/sort metadata, and [Filter adapters](filter_adapters.md) for adapter-shaped params.
