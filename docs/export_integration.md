# Export integration

Rails Table Preferences does not generate CSV, Excel, or report files by itself.

Instead, it provides a small export payload helper so host applications can reuse saved table display preferences when building exports.

If you generated the optional demo screen with `--with-demo`, the demo now includes a lightweight preview of the current `headers` and `column_keys` output so you can compare helper results before wiring a real export action. See [Demo screen generator](demo.md).

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

## Minimal list-to-export wiring

The common host app flow is:

1. show a normal list screen with filters and a selected `table_preference_name`
2. submit the same params to a separate export action
3. build the file from `headers` and `columns` in the export action

Minimal list screen example:

```erb
<%= form_with url: export_orders_path, method: :get, local: true do %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] || "default" %>
  <%= hidden_field_tag :search_word, params[:search_word] if params[:search_word].present? %>
  <%= hidden_field_tag :sort, params[:sort] if params[:sort].present? %>

  <%= submit_tag "CSV出力" %>
<% end %>
```

If the index screen already uses `table_preferences_hidden_fields(...)` for saved filter/sort UI state, keep that form submission separate from the export button and pass only the params that the export action actually needs. Rails Table Preferences owns the saved table preference payload; the host app still owns which query params are valid for export.

Minimal export action example:

```ruby
def export
  columns = table_columns
  export_payload = rails_table_preference_export_payload(
    table_key: :orders,
    columns: columns,
    name: params[:table_preference_name]
  )

  scoped_orders = Order.search(params)

  csv_string = CSV.generate do |csv|
    csv << export_payload["headers"]

    scoped_orders.find_each do |order|
      csv << export_payload["columns"].map do |column|
        order.public_send(column["export_key"] || column["key"])
      end
    end
  end

  send_data csv_string, filename: "orders.csv"
end
```

This example intentionally keeps file generation in the host app. Rails Table Preferences only provides ordered column metadata and the selected preset name.

## How to use each payload key

- `headers`: write the exported header row in the same order the user sees in the table.
- `columns`: use when export values need metadata such as `export_key`, `label`, `group`, or visibility state.
- `column_keys`: use when the export layer only needs the ordered display/preference keys for serializer mapping, SELECT whitelists, or downstream report builders. This list stays based on each column's `key`; it does not switch to `export_key` when export metadata is present.

When the host app already has a serializer or report object keyed by the displayed table columns, `column_keys` is often the smallest integration surface. When value extraction needs a different method or attribute, read `export_key` from each `columns` entry instead.

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

`include_hidden: true` only changes how the saved visibility preference is applied to the export payload. It is not an authorization bypass and it does not make every hidden column safe to export.

Before exporting hidden or sensitive columns, keep this decision in the host application:

- maintain an allowlist or policy for exportable column keys before calling `public_send`, serializers, or report builders
- treat hidden columns as a display preference, not as a sensitivity marker
- exclude sensitive columns even when they are visible in the table unless the current user and export action are allowed to receive them
- document or test whether `include_hidden: true` is available to all users, admin-only users, or only specific export flows

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

`export_key` is stored on each `columns` entry as value-extraction metadata. It does not rename the display/preference key returned in `column_keys`.

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
- maintaining the allowlist or policy for exportable columns
- deciding whether sensitive columns should ever be selected or rendered
- testing export actions that use `include_hidden: true`