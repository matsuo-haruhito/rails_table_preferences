# Practical examples

This document shows practical integration patterns for Rails applications that already have list screens with `search(params)` and `order_by(params[:sort])` style APIs.

The examples intentionally keep database search execution in the host application. Rails Table Preferences only provides display preferences, saved filter/sort UI state, and adapter params.

## Example: warehouse stock list

Controller:

```ruby
class WarehouseStocksController < ApplicationController
  def index
    @table_columns = warehouse_stock_table_columns

    preference_params = rails_table_preference_params(
      table_key: :warehouse_stocks,
      name: params[:table_preference_name],
      columns: @table_columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    @warehouse_stocks = WarehouseStock
      .warehouse_stocks_each_items
      .eager_load(:item, :warehouse)
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])
      .page(params[:page])
  end

  private

  def warehouse_stock_table_columns
    [
      table_preferences_column(
        :warehouse_name,
        label: "倉庫名",
        filter: { type: :text, param: :warehouse_name },
        sortable: true,
        default_width: 180
      ),
      table_preferences_column(
        :item_code,
        label: "商品コード",
        filter: { type: :text, param: :item_code },
        sortable: true,
        default_width: 140
      ),
      table_preferences_column(
        :item_name,
        label: "商品名",
        filter: { type: :text, param: :search_word },
        sortable: true,
        default_width: 260,
        default_truncate: 30
      ),
      table_preferences_column(
        :stock_quantity,
        label: "在庫数",
        filter: { type: :number, from_param: :from_stock_quantity, to_param: :to_stock_quantity },
        sortable: true,
        default_width: 100
      ),
      table_preferences_column(
        :last_arrival_date,
        label: "最終入荷日",
        filter: { type: :date, from_param: :from_arrival_date, to_param: :to_arrival_date },
        sortable: true,
        sort_param: :arrival_date,
        default_width: 140
      ),
      table_preferences_column(
        :internal_cost,
        label: "内部原価",
        ignored: true
      )
    ]
  end
end
```

View:

```erb
<%= table_preferences_editor(
  table_key: :warehouse_stocks,
  name: params[:table_preference_name] || "default",
  settings: @table_preference_settings,
  columns: @table_columns,
  title: "在庫一覧の表示設定"
) %>

<%= form_with url: warehouse_stocks_path, method: :get do %>
  <%= text_field_tag :search_word, params[:search_word], placeholder: "商品名" %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] if params[:table_preference_name].present? %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @table_columns
  ) %>

  <%= submit_tag "検索" %>
<% end %>

<%= table_preferences_table_tag(
  table_key: :warehouse_stocks,
  name: params[:table_preference_name] || "default",
  settings: @table_preference_settings,
  columns: @table_columns,
  class: "table"
) do %>
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="warehouse_name">倉庫名</th>
      <th data-rails-table-preferences-column-key="item_code">商品コード</th>
      <th data-rails-table-preferences-column-key="item_name">商品名</th>
      <th data-rails-table-preferences-column-key="stock_quantity">在庫数</th>
      <th data-rails-table-preferences-column-key="last_arrival_date">最終入荷日</th>
    </tr>
  </thead>
  <tbody>
    <% @warehouse_stocks.each do |stock| %>
      <tr>
        <td data-rails-table-preferences-column-key="warehouse_name"><%= stock.warehouse.name %></td>
        <td data-rails-table-preferences-column-key="item_code"><%= stock.item.code %></td>
        <td data-rails-table-preferences-column-key="item_name"><%= stock.item.name %></td>
        <td data-rails-table-preferences-column-key="stock_quantity"><%= stock.quantity %></td>
        <td data-rails-table-preferences-column-key="last_arrival_date"><%= l(stock.last_arrival_date) if stock.last_arrival_date %></td>
      </tr>
    <% end %>
  </tbody>
<% end %>
```

Optional export action for the same list screen:

```ruby
def export
  columns = warehouse_stock_table_columns

  preference_params = rails_table_preference_params(
    table_key: :warehouse_stocks,
    name: params[:table_preference_name],
    columns: columns
  )

  merged_params = params.to_unsafe_h.merge(preference_params)

  export_payload = rails_table_preference_export_payload(
    table_key: :warehouse_stocks,
    columns: columns,
    name: params[:table_preference_name]
  )

  warehouse_stocks = WarehouseStock
    .warehouse_stocks_each_items
    .eager_load(:item, :warehouse)
    .search(merged_params)
    .order_by(merged_params["sort"] || params[:sort])

  headers = export_payload["headers"]
  rows = warehouse_stocks.map do |stock|
    export_payload["columns"].map do |column|
      stock.public_send(column["export_key"] || column["key"])
    end
  end

  # Host app owns CSV/report generation.
end
```

Export link that keeps the selected preset and current filters:

```erb
<%= link_to(
  "CSV export",
  export_warehouse_stocks_path(
    request.query_parameters.merge(
      table_preference_name: params[:table_preference_name],
      format: :csv
    )
  )
) %>
```

## Example: customer shipment list with Ransack

Controller:

```ruby
class ShipmentsController < ApplicationController
  def index
    @table_columns = shipment_table_columns

    ransack_params = rails_table_preference_params(
      table_key: :shipments,
      name: params[:table_preference_name],
      columns: @table_columns,
      adapter: :ransack
    )

    q_params = params.fetch(:q, {}).to_unsafe_h.merge(ransack_params)
    @q = Shipment.ransack(q_params)
    @shipments = @q.result.includes(:customer).page(params[:page])
  end

  private

  def shipment_table_columns
    [
      table_preferences_column(
        :customer_name,
        label: "得意先名",
        filter: { type: :text, operators: %i[contains equals blank] },
        sortable: true,
        default_width: 240
      ),
      table_preferences_column(
        :shipment_status,
        label: "出荷状態",
        filter: { type: :select, options: ["未出荷", "出荷済", "保留"] },
        sortable: true,
        default_width: 120
      ),
      table_preferences_column(
        :delivery_date,
        label: "納品日",
        filter: { type: :date, operators: %i[gteq lteq between blank present] },
        sortable: true,
        default_width: 140
      )
    ]
  end
end
```

View form integration:

```erb
<%= search_form_for @q, url: shipments_path, method: :get do |f| %>
  <%= f.search_field :customer_name_cont, placeholder: "得意先名" %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @table_columns,
    adapter: :ransack,
    namespace: :q
  ) %>

  <%= submit_tag "検索" %>
<% end %>
```

## Notes

- Prefer `ignored: true` for columns that should never appear in the user-facing column editor.
- Use `param`, `values_param`, `from_param`, `to_param`, and `sort_param` to match existing host application params.
- Keep authorization, joins, allowed searchable fields, and business-specific query behavior in the host application.
- Use `table_preferences_hidden_fields` when a normal search form should submit saved preference params.
- Use `rails_table_preference_params` or `rails_table_preference_merged_params` when the controller should merge saved params directly.
- When the same screen also has CSV/report export, forward `table_preference_name` and the current query params to the export action, then build headers/rows from `rails_table_preference_export_payload`.