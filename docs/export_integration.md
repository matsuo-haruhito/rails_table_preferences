# Export integration

Rails Table Preferences does not generate CSV, Excel, or report files by itself.

Instead, it provides a small export payload helper so host applications can reuse saved table display preferences when building exports.

## Controller helper

Use `rails_table_preference_export_payload` from a controller that includes `RailsTablePreferences::Controller`:

```ruby
class OrdersController < ApplicationController
  def index
    @columns = table_columns
    @orders = Order.search(params)
  end

  def export
    columns = table_columns
    export_payload = rails_table_preference_export_payload(
      table_key: :orders,
      columns: columns,
      name: params[:table_preference_name]
    )

    rows = Order.search(params).find_each.map do |order|
      export_payload["columns"].map do |column|
        order.public_send(column["export_key"] || column["key"])
      end
    end

    # Host app owns CSV/Excel generation.
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

The returned payload contains:

```ruby
{
  "columns" => [...],
  "column_keys" => ["customer_name", "order_no"],
  "headers" => ["得意先名", "受注番号"],
  "settings" => {...}
}
```

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
