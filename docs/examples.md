# Practical examples

This document shows practical integration patterns for Rails applications that already have list screens with `search(params)` and `order_by(params[:sort])` style APIs.

The examples intentionally keep database search execution in the host application. Rails Table Preferences only provides display preferences, saved filter/sort UI state, and adapter params.

## Example: convention-first order list with `resource_table_for`

Use this pattern when the screen already has its own search form, pagination, and controller query code, but you want the table surface itself to follow Active Record inference instead of a hand-written column array.

Profile:

```ruby
class OrdersIndexTableProfile < RailsTablePreferences::TableProfile
  model Order

  exclude :internal_memo, :deleted_at
  order :order_no, :customer_id, :status, :delivery_date, :total_amount
  label :customer_id, "Customer"

  display :customer_id do |order, view|
    view.link_to order.customer.name, view.customer_path(order.customer)
  end
end
```

Controller:

```ruby
class OrdersController < ApplicationController
  def index
    @orders = Order
      .includes(:customer)
      .search(params)
      .order_by(params[:sort])
      .page(params[:page])
  end
end
```

View composition:

```erb
<%= form_with url: orders_path, method: :get do %>
  <%= text_field_tag :search_word, params[:search_word], placeholder: "得意先名で検索" %>
  <%= select_tag :status,
                 options_for_select([["すべて", ""], ["受付", "pending"], ["出荷済", "shipped"]], params[:status]) %>
  <%= submit_tag "検索" %>
<% end %>

<%= resource_table_for @orders, profile: OrdersIndexTableProfile %>

<%= paginate @orders %>
```

Why this pattern works:

- the host app keeps its existing query, authorization, and pagination flow
- `resource_table_for` owns only the convention-first table surface and saved display preferences
- the profile stays a delta layer for small ordering, exclusion, and display overrides instead of replacing the whole table definition
- if the screen later needs saved filter/sort params to round-trip through the existing form, add the controller/view wiring from [Controller integration](controller_integration.md) without replacing `resource_table_for`

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

## Example: keep an existing HTML table partial and mount the controller root manually

Use this pattern when the host app already owns the `<table>` markup through a shared partial, HTML rewrite, or another table builder, and you want to add saved display preferences without rewriting that table into `table_preferences_table_tag(...)`.

Controller:

```ruby
class LegacyOrdersController < ApplicationController
  def index
    @table_key = :legacy_orders
    @table_preference_name = params[:table_preference_name].presence || "default"
    @table_columns = legacy_order_table_columns
    @table_preference_settings = rails_table_preference_settings(
      table_key: @table_key,
      name: @table_preference_name,
      fallback: {}
    )

    preference_params = rails_table_preference_params(
      table_key: @table_key,
      name: @table_preference_name,
      columns: @table_columns
    )
    merged_params = params.to_unsafe_h.merge(preference_params)

    @orders = Order
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])
      .page(params[:page])

    encoded_table_key = ERB::Util.url_encode(@table_key)
    encoded_preference_name = ERB::Util.url_encode(@table_preference_name)

    @table_preference_collection_url = "/rails_table_preferences/preferences/#{encoded_table_key}"
    @table_preference_url = "#{@table_preference_collection_url}/#{encoded_preference_name}"
  end

  private

  def legacy_order_table_columns
    [
      table_preferences_column(
        :order_no,
        label: "受注番号",
        sortable: true,
        default_width: 140
      ),
      table_preferences_column(
        :customer_name,
        label: "得意先名",
        filter: { type: :text, param: :search_word },
        sortable: true,
        default_width: 240,
        overflow: :ellipsis
      )
    ]
  end
end
```

View composition:

```erb
<%= table_preferences_editor(
  table_key: @table_key,
  name: @table_preference_name,
  settings: @table_preference_settings,
  columns: @table_columns,
  title: "受注一覧の表示設定"
) %>

<div
  data-controller="rails-table-preferences"
  data-rails-table-preferences-table-key-value="<%= @table_key %>"
  data-rails-table-preferences-name-value="<%= @table_preference_name %>"
  data-rails-table-preferences-collection-url-value="<%= @table_preference_collection_url %>"
  data-rails-table-preferences-url-value="<%= @table_preference_url %>"
  data-rails-table-preferences-columns-value="<%= @table_columns.to_json %>"
  data-rails-table-preferences-settings-value="<%= @table_preference_settings.to_json %>">
  <table class="table">
    <thead>
      <tr>
        <th data-rails-table-preferences-column-key="order_no">受注番号</th>
        <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
        <th>備考</th>
        <th>操作</th>
      </tr>
    </thead>
    <tbody>
      <% @orders.each do |order| %>
        <tr>
          <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
          <td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
          <td><%= truncate(order.note, length: 40) %></td>
          <td><%= link_to "詳細", order_path(order) %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

Why this pattern works:

- the host app keeps the existing table partial and can leave note/action columns fully outside Rails Table Preferences control
- the gem still owns visibility, order, width, filters, sorts, and preset API calls for the managed columns because both `th` and `td` cells expose matching `data-rails-table-preferences-column-key` values
- the same `@table_columns` and `@table_preference_settings` can feed both `table_preferences_editor(...)` and the helper-free controller root, so the editor and table stay aligned
- query execution, authorization, export actions, and any `config.mount_path` override still belong to the host app

For the exact attribute list and table-target rules, see [JavaScript controller notes](javascript_controller.md). For helper-free URL ownership and custom mount path examples, see [Helper-free controller root URLs](helper_free_controller_root_urls.md). For the lighter introductory version of this pattern, see [Quick start](quick_start.md).

## Example: keep the search form and export action separate

Use this pattern when one list screen needs all of these at once:

- a normal GET search form for the visible table
- saved filter/sort UI state from Rails Table Preferences
- a separate CSV or Excel export action that should follow the same effective query and selected preset

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
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])
      .page(params[:page])
  end

  def export
    @table_columns = warehouse_stock_table_columns

    export_payload = rails_table_preference_export_payload(
      table_key: :warehouse_stocks,
      name: params[:table_preference_name],
      columns: @table_columns
    )

    scoped_stocks = WarehouseStock
      .search(export_query_params)
      .order_by(export_query_params["sort"])

    value_extractors = {
      "warehouse_name" => ->(stock) { stock.warehouse.name },
      "item_code" => ->(stock) { stock.item.code },
      "item_name" => ->(stock) { stock.item.name },
      "stock_quantity" => ->(stock) { stock.quantity },
      "last_arrival_date" => ->(stock) { stock.last_arrival_date }
    }

    csv_string = CSV.generate do |csv|
      csv << export_payload["headers"]

      scoped_stocks.find_each do |stock|
        csv << export_payload["export_keys"].map do |key|
          value_extractors.fetch(key.to_s).call(stock)
        end
      end
    end

    send_data csv_string, filename: "warehouse_stocks.csv"
  end

  private

  def export_query_params
    params.to_unsafe_h.slice(
      "search_word",
      "warehouse_name",
      "item_code",
      "from_stock_quantity",
      "to_stock_quantity",
      "from_arrival_date",
      "to_arrival_date",
      "sort"
    )
  end
end
```

View composition:

```erb
<%= form_with url: warehouse_stocks_path, method: :get, local: true do %>
  <%= text_field_tag :search_word, params[:search_word], placeholder: "商品名" %>
  <%= text_field_tag :warehouse_name, params[:warehouse_name], placeholder: "倉庫名" %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] if params[:table_preference_name].present? %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @table_columns
  ) %>

  <%= submit_tag "検索" %>
<% end %>

<%= form_with url: export_warehouse_stocks_path, method: :get, local: true do %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] if params[:table_preference_name].present? %>
  <%= hidden_field_tag :search_word, params[:search_word] if params[:search_word].present? %>
  <%= hidden_field_tag :warehouse_name, params[:warehouse_name] if params[:warehouse_name].present? %>
  <%= hidden_field_tag :item_code, params[:item_code] if params[:item_code].present? %>
  <%= hidden_field_tag :from_stock_quantity, params[:from_stock_quantity] if params[:from_stock_quantity].present? %>
  <%= hidden_field_tag :to_stock_quantity, params[:to_stock_quantity] if params[:to_stock_quantity].present? %>
  <%= hidden_field_tag :from_arrival_date, params[:from_arrival_date] if params[:from_arrival_date].present? %>
  <%= hidden_field_tag :to_arrival_date, params[:to_arrival_date] if params[:to_arrival_date].present? %>
  <%= hidden_field_tag :sort, params[:sort] if params[:sort].present? %>

  <%= submit_tag "CSV出力" %>
<% end %>
```

Why this split works:

- the search form owns user-entered query params plus `table_preferences_hidden_fields(...)`, so saved filter/sort UI state can round-trip through the normal index request
- the export form owns only the params that the export action actually accepts, which keeps export authorization and query scope explicit in the host app
- `table_preference_name` still selects the same saved column order, visibility, and labels when `rails_table_preference_export_payload(...)` builds export metadata
- the export action maps ordered `export_keys` through a host-app-owned extractor allowlist instead of dispatching arbitrary methods from table preference metadata
- query execution and file generation remain host app responsibilities even when the export follows the same visible table state; see [Export integration](export_integration.md) for hidden-column and sensitive-column boundaries

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

## Example: admin page with a create form, editor, and list table

Use this pattern when one management screen needs all three responsibilities at once:

- create or update a business record
- save table display preferences
- browse the current record list

Keep those responsibilities as separate form submissions even when they appear on the same page.

Controller:

```ruby
class Admin::DocumentSetsController < ApplicationController
  def index
    @document_set = DocumentSet.new
    load_document_set_table_state
  end

  def create
    @document_set = DocumentSet.new(document_set_params)

    if @document_set.save
      redirect_to admin_document_sets_path, notice: "作成しました"
    else
      load_document_set_table_state
      render :index, status: :unprocessable_entity
    end
  end

  private

  def load_document_set_table_state
    @table_columns = document_set_table_columns
    @table_preference_settings = rails_table_preference_settings(
      table_key: :admin_document_sets,
      name: params[:table_preference_name],
      fallback: {}
    )

    preference_params = rails_table_preference_params(
      table_key: :admin_document_sets,
      name: params[:table_preference_name],
      columns: @table_columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    @document_sets = DocumentSet
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])
      .page(params[:page])
  end

  def document_set_table_columns
    [
      table_preferences_column(:code, label: "セットコード", sortable: true, default_width: 160),
      table_preferences_column(:name, label: "セット名", sortable: true, default_width: 240),
      table_preferences_column(:document_count, label: "文書数", sortable: true, default_width: 120),
      table_preferences_column(
        :updated_at,
        label: "更新日時",
        sortable: true,
        filter: { type: :date, from_param: :from_updated_at, to_param: :to_updated_at },
        default_width: 180
      )
    ]
  end

  def document_set_params
    params.require(:document_set).permit(:code, :name)
  end
end
```

View composition:

```erb
<%= form_with model: @document_set, url: admin_document_sets_path do |f| %>
  <%= f.text_field :code, placeholder: "セットコード" %>
  <%= f.text_field :name, placeholder: "セット名" %>
  <%= f.submit "登録" %>
<% end %>

<%= table_preferences_editor(
  table_key: :admin_document_sets,
  name: params[:table_preference_name] || "default",
  settings: @table_preference_settings,
  columns: @table_columns,
  title: "一覧の表示設定"
) %>

<%= form_with url: admin_document_sets_path, method: :get do %>
  <%= text_field_tag :search_word, params[:search_word], placeholder: "セット名で検索" %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] if params[:table_preference_name].present? %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @table_columns
  ) %>

  <%= submit_tag "検索" %>
<% end %>

<%= table_preferences_table_tag(
  table_key: :admin_document_sets,
  name: params[:table_preference_name] || "default",
  settings: @table_preference_settings,
  columns: @table_columns,
  class: "table"
) do %>
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="code">セットコード</th>
      <th data-rails-table-preferences-column-key="name">セット名</th>
      <th data-rails-table-preferences-column-key="document_count">文書数</th>
      <th data-rails-table-preferences-column-key="updated_at">更新日時</th>
    </tr>
  </thead>
  <tbody>
    <% @document_sets.each do |document_set| %>
      <tr>
        <td data-rails-table-preferences-column-key="code"><%= document_set.code %></td>
        <td data-rails-table-preferences-column-key="name"><%= document_set.name %></td>
        <td data-rails-table-preferences-column-key="document_count"><%= document_set.document_count %></td>
        <td data-rails-table-preferences-column-key="updated_at"><%= l(document_set.updated_at) %></td>
      </tr>
    <% end %>
  </tbody>
<% end %>
```

Why this split works:

- the create form owns record validation and persistence
- validation failures render the same table state setup as `index`, so the editor, hidden fields, and table tag still receive `@table_preference_settings`
- the editor owns only table display preferences and preset actions
- the search form owns user-entered query params plus `table_preferences_hidden_fields(...)`
- the table stays a normal host app list view and only opts into Rails Table Preferences through column keys

If the page later adds CSV/export actions, keep those as another separate submission and pass only the params needed for export. See [Export integration](export_integration.md).

## Example: order list with fixed columns, grouped headers, and horizontal scroll

Use this pattern when one host-app list screen needs all of these at once:

- pinned identifier columns that stay visible during horizontal scrolling
- grouped business columns in a two-row table header
- the same editor and search-form flow as the simpler examples above

Controller:

```ruby
class OrdersController < ApplicationController
  def index
    @table_columns = order_table_columns

    preference_params = rails_table_preference_params(
      table_key: :orders,
      name: params[:table_preference_name],
      columns: @table_columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    @orders = Order
      .includes(:customer, :delivery_destination)
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])
      .page(params[:page])
  end

  private

  def order_table_columns
    [
      table_preferences_column(
        :order_no,
        label: "受注番号",
        fixed: true,
        sortable: true,
        default_width: 140
      ),
      table_preferences_column(
        :customer_code,
        label: "得意先コード",
        fixed: true,
        sortable: true,
        default_width: 140,
        group: { key: :customer, label: "得意先情報" }
      ),
      table_preferences_column(
        :customer_name,
        label: "得意先名",
        sortable: true,
        default_width: 240,
        overflow: :ellipsis,
        group: { key: :customer, label: "得意先情報" }
      ),
      table_preferences_column(
        :delivery_name,
        label: "納品先",
        filter: { type: :text, param: :delivery_name },
        default_width: 220,
        overflow: :ellipsis,
        group: { key: :delivery, label: "配送情報" }
      ),
      table_preferences_column(
        :delivery_date,
        label: "納品日",
        sortable: true,
        filter: { type: :date, from_param: :from_delivery_date, to_param: :to_delivery_date },
        default_width: 140,
        group: { key: :delivery, label: "配送情報" }
      ),
      table_preferences_column(
        :total_amount,
        label: "金額",
        sortable: true,
        default_width: 120
      )
    ]
  end
end
```

View composition:

```erb
<%= table_preferences_editor(
  table_key: :orders,
  name: params[:table_preference_name] || "default",
  settings: @table_preference_settings,
  columns: @table_columns,
  title: "受注一覧の表示設定"
) %>

<%= form_with url: orders_path, method: :get do %>
  <%= text_field_tag :delivery_name, params[:delivery_name], placeholder: "納品先で検索" %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] if params[:table_preference_name].present? %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @table_columns
  ) %>

  <%= submit_tag "検索" %>
<% end %>

<div class="orders-table-scroll">
  <%= table_preferences_table_tag(
    table_key: :orders,
    name: params[:table_preference_name] || "default",
    settings: @table_preference_settings,
    columns: @table_columns,
    class: "orders-table"
  ) do %>
    <thead>
      <tr>
        <th rowspan="2" data-rails-table-preferences-column-key="order_no">受注番号</th>
        <th colspan="2">得意先情報</th>
        <th colspan="2">配送情報</th>
        <th rowspan="2" data-rails-table-preferences-column-key="total_amount">金額</th>
      </tr>
      <tr>
        <th class="orders-table__pin-after-order-no" data-rails-table-preferences-column-key="customer_code">得意先コード</th>
        <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
        <th data-rails-table-preferences-column-key="delivery_name">納品先</th>
        <th data-rails-table-preferences-column-key="delivery_date">納品日</th>
      </tr>
    </thead>
    <tbody>
      <% @orders.each do |order| %>
        <tr>
          <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
          <td class="orders-table__pin-after-order-no" data-rails-table-preferences-column-key="customer_code"><%= order.customer.code %></td>
          <td data-rails-table-preferences-column-key="customer_name"><%= order.customer.name %></td>
          <td data-rails-table-preferences-column-key="delivery_name"><%= order.delivery_destination.name %></td>
          <td data-rails-table-preferences-column-key="delivery_date"><%= l(order.delivery_date) if order.delivery_date %></td>
          <td data-rails-table-preferences-column-key="total_amount"><%= number_to_currency(order.total_amount) %></td>
        </tr>
      <% end %>
    </tbody>
  <% end %>
</div>
```

Minimal CSS baseline:

```css
.orders-table-scroll {
  max-width: 100%;
  overflow-x: auto;
}

.orders-table {
  min-width: 1100px;
  border-collapse: separate;
}

.orders-table th,
.orders-table td {
  background: white;
}

.orders-table__pin-after-order-no {
  --rails-table-preferences-pinned-left: 140px;
}

.orders-table [data-rails-table-preferences-pinned="true"] {
  z-index: 3;
  background: white;
}
```

Why this pattern works:

- fixed and group metadata stay in the column definitions, while the grouped header HTML stays fully owned by the host app
- the horizontal scroll wrapper keeps sticky columns anchored inside the table scroller instead of the whole page
- the second pinned column opts into an explicit `--rails-table-preferences-pinned-left` offset because final sticky math depends on the host app's table width and border policy
- leaf header and body cells still carry `data-rails-table-preferences-column-key`, so saved visibility, order, width, and pinned metadata continue to apply normally
- the CSS above is only a baseline; shadows, borders, responsive tuning, and design-system polish still belong to the host app

See [Fixed columns and column groups](fixed_columns_and_groups.md) for the metadata contract and responsibility boundary.

## Notes

- Prefer `ignored: true` for columns that should never appear in the user-facing column editor.
- Use `param`, `values_param`, `from_param`, `to_param`, and `sort_param` to match existing host application params.
- Keep authorization, joins, allowed searchable fields, and business-specific query behavior in the host application.
- Use `table_preferences_hidden_fields` when a normal search form should submit saved preference params.
- Use `rails_table_preference_params` or `rails_table_preference_merged_params` when the controller should merge saved params directly.
