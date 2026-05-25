# Export integration

Rails Table Preferences does not generate CSV, Excel, or report files by itself.

Instead, it provides a small export payload helper so host applications can reuse saved table display preferences when building exports.

## Minimal end-to-end wiring

The smallest practical pattern is:

1. Keep using the host app's normal search/query code on the list screen.
2. Forward the current `table_preference_name` and any existing query params to the export action.
3. In the export action, resolve the saved preference again and build the export payload from the same `table_key`.

Controller:

```ruby
class OrdersController < ApplicationController
  def index
    @columns = table_columns

    preference_params = rails_table_preference_params(
      table_key: :orders,
      name: params[:table_preference_name],
      columns: @columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    @orders = Order
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])
  end

  def export
    columns = table_columns

    preference_params = rails_table_preference_params(
      table_key: :orders,
      name: params[:table_preference_name],
      columns: columns
    )

    merged_params = params.to_unsafe_h.merge(preference_params)

    export_payload = rails_table_preference_export_payload(
      table_key: :orders,
      columns: columns,
      name: params[:table_preference_name]
    )

    orders = Order
      .search(merged_params)
      .order_by(merged_params["sort"] || params[:sort])

    headers = export_payload["headers"]
    rows = orders.map do |order|
      export_payload["columns"].map do |column|
        method_name = column["export_key"] || column["key"]
        order.public_send(method_name)
      end
    end

    # Host app owns CSV/Excel/report generation and response rendering.
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

View:

```erb
<%= link_to(
  "CSV export",
  export_orders_path(
    request.query_parameters.merge(
      table_preference_name: params[:table_preference_name],
      format: :csv
    )
  )
) %>
```

This keeps the selected preset name and current search params on the export request without moving CSV/report generation into the gem.

If the list screen already uses a search form with `table_preferences_hidden_fields`, keep using the same host-app query params for the export action as well. The important part is that the export action receives the same `table_preference_name` and resolves the same saved preference again.

## Controller helper

Use `rails_table_preference_export_payload` from a controller that includes `RailsTablePreferences::Controller`:

```ruby
export_payload = rails_table_preference_export_payload(
  table_key: :orders,
  columns: columns,
  name: params[:table_preference_name]
)
```

The returned payload contains:

```ruby
{
  "columns" => [...],
  "column_keys" => ["customer_name", "order_no"],
  "headers" => ["得意先名", "受注番号"],
  "settings" => {...}
}
```

Use the payload keys like this:

- `column_keys`: the saved visible/export order as plain keys, useful when selecting attributes or building a simple CSV column list.
- `headers`: the final user-facing labels in export order.
- `columns`: the full normalized column metadata, useful when the export layer needs `export_key`, group metadata, or additional per-column options.
- `settings`: the normalized saved settings that produced the export order.

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