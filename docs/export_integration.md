# Export integration

Rails Table Preferences does not generate CSV, Excel, or report files by itself.

Instead, it provides a small export payload helper so host applications can reuse saved table display preferences when building exports.

## Minimal list-screen wiring

A practical export flow usually keeps three values aligned between the list screen and the export action:

- the same `table_key`
- the same `columns`
- the same `table_preference_name`

That lets the export action reuse the same saved visibility/order/label choices that the user sees on screen.

View example:

```erb
<%= form_with url: export_orders_path, method: :get do %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] if params[:table_preference_name].present? %>
  <%= hidden_field_tag :search_word, params[:search_word] if params[:search_word].present? %>

  <%= table_preferences_hidden_fields(
    settings: @table_preference_settings,
    columns: @columns
  ) %>

  <%= submit_tag "CSV export" %>
<% end %>
```

The form above keeps the selected preset name and the saved filter/sort state together. The export action can then rebuild the same search params before generating rows.

## Controller helper

Use `rails_table_preference_export_payload` from a controller that includes `RailsTablePreferences::Controller`:

```ruby
class OrdersController < ApplicationController
  def index
    @columns = table_columns
    search_params = params.to_unsafe_h.merge(
      rails_table_preference_params(
        table_key: :orders,
        columns: @columns,
        name: params[:table_preference_name]
      )
    )

    @orders = Order.search(search_params)
  end

  def export
    columns = table_columns
    search_params = params.to_unsafe_h.merge(
      rails_table_preference_params(
        table_key: :orders,
        columns: columns,
        name: params[:table_preference_name]
      )
    )

    export_payload = rails_table_preference_export_payload(
      table_key: :orders,
      columns: columns,
      name: params[:table_preference_name]
    )

    rows = Order.search(search_params).find_each.map do |order|
      export_payload["columns"].map do |column|
        order.public_send(column["export_key"] || column["key"])
      end
    end

    csv_string = CSV.generate do |csv|
      csv << export_payload["headers"]
      rows.each { |row| csv << row }
    end

    send_data csv_string, filename: "orders.csv"
  end

  private

  def table_columns
    [
      table_preferences_column(:order_no, label: "受注番号"),
      table_preferences_column(:customer_name, label: "得意先名"),
      table_preferences_column(:amount, label: "金額")
    ]
  end
end
```

The host app still owns the actual query semantics and file generation. Rails Table Preferences only decides which columns are visible, in what order, and with which labels.

The returned payload contains:

```ruby
{
  "columns" => [...],
  "column_keys" => ["customer_name", "order_no"],
  "headers" => ["得意先名", "受注番号"],
  "settings" => {...}
}
```

## What each payload field is for

- `column_keys`: a compact ordered key list for serializer allowlists or lightweight export logic.
- `headers`: the human-facing header row for CSV, Excel, or report output.
- `columns`: the full ordered column metadata, including `label`, `group`, `export_key`, saved `order`, and saved `visible` state.
- `settings`: the normalized saved preference payload that produced the export ordering.

## Direct object usage

You can use the helper object directly outside controllers:

```ruby
payload = RailsTablePreferences::ExportPayload.call(
  settings: settings,
  columns: columns
)
```

## Hidden columns

Hidden columns are excluded by default:

```ruby
payload = rails_table_preference_export_payload(
  table_key: :orders,
  columns: columns
)
```

Include hidden columns when needed:

```ruby
payload = rails_table_preference_export_payload(
  table_key: :orders,
  columns: columns,
  include_hidden: true
)
```

## Export keys

Use `export_key` in a hash column definition when the display key differs from the export method or attribute:

```ruby
columns = [
  {
    key: :customer_name,
    label: "得意先名",
    export_key: :customer_display_name
  }
]
```

Then export code can read:

```ruby
column["export_key"] || column["key"]
```

A practical rule is to keep `key` aligned with the on-screen column identity, and use `export_key` only when the export should call a different method or presenter field.

## Column groups

Group metadata is preserved in the export payload:

```ruby
table_preferences_column(
  :customer_name,
  label: "得意先名",
  group: { key: :customer, label: "得意先情報" }
)
```

This is useful for Excel exports with grouped headers. Rails Table Preferences only passes the metadata through; the host application decides how to render grouped export headers.

## Responsibility boundary

Rails Table Preferences owns:

- resolving saved table preferences
- filtering hidden columns unless `include_hidden: true`
- ordering export columns according to saved display order
- returning labels and metadata

The host application owns:

- authorization
- query execution
- CSV/Excel/report file generation
- formatting values
- deciding whether hidden columns should be exportable
- deciding whether sensitive columns should ever be selected or rendered
