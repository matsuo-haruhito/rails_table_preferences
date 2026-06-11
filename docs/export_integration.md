# Export integration

Rails Table Preferences does not generate CSV, Excel, or report files by itself.

Instead, it provides a small export payload helper so host applications can reuse saved table display preferences when building exports.

If you generated the optional demo screen with `--with-demo`, the demo now includes a lightweight preview of the current `headers` and `column_keys` output so you can compare helper results before wiring a real export action. See [Demo screen generator](demo.md).

## Controller helper

Use `rails_table_preference_export_payload` from a controller that includes `RailsTablePreferences::Controller`:

```ruby
class OrdersController < ApplicationController
  EXPORT_VALUE_EXTRACTORS = {
    "order_no" => ->(order) { order.order_no },
    "customer_name" => ->(order) { order.customer_name },
    "amount" => ->(order) { order.amount }
  }.freeze

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
      export_payload["export_keys"].map do |key|
        EXPORT_VALUE_EXTRACTORS.fetch(key.to_s).call(order)
      end
    end

    # Host app owns CSV/Excel generation.
  end

  private

  def table_columns
    [
      table_preferences_column(:order_no, label: "受注番号"),
      table_preferences_column(:customer_name, label: "得意先名", export_key: :customer_display_name),
      table_preferences_column(:amount, label: "金額")
    ]
  end
end
```

`export_keys` is ordered value-extraction metadata, not an authorization allowlist. Keep the extraction map, serializer, policy check, or explicit case statement in the host app so saved display preferences cannot call arbitrary model methods.

The returned payload contains:

```ruby
{
  "columns" => [...],
  "column_keys" => ["customer_name", "order_no"],
  "export_keys" => ["customer_display_name", "order_no"],
  "headers" => ["得意先名", "受注番号"],
  "settings" => {...}
}
```

The export payload is the column snapshot for the file. It is not the source of truth for list query params, and it does not execute saved filters or sorts. When an export should use the same filter/sort state as the current list, build those query params separately with the controller-param helpers described in [Controller integration](controller_integration.md), or merge the host app's current request params by policy in the export action.

## Minimal list-to-export wiring

The common host app flow is:

1. show a normal list screen with filters and a selected `table_preference_name`
2. decide which filter/sort params the export action should receive
3. submit those params to a separate export action
4. build the file from `headers` and `columns` in the export action

Minimal list screen example:

```erb
<%= form_with url: export_orders_path, method: :get, local: true do %>
  <%= hidden_field_tag :table_preference_name, params[:table_preference_name] || "default" %>
  <%= hidden_field_tag :search_word, params[:search_word] if params[:search_word].present? %>
  <%= hidden_field_tag :sort, params[:sort] if params[:sort].present? %>

  <%= submit_tag "CSV出力" %>
<% end %>
```

If the export should apply the selected saved preset instead of only the current request params, resolve that filter/sort state in the export action with `rails_table_preference_params(...)` or `rails_table_preference_merged_params(...)`:

```ruby
export_params = rails_table_preference_merged_params(
  table_key: :orders,
  columns: columns,
  name: params[:table_preference_name]
)

scoped_orders = Order.search(export_params)
```

Use this pattern when the selected preset should be authoritative for saved filter/sort keys. If the current request form should remain authoritative, build the hash explicitly, for example by merging in the opposite order or by only forwarding the query params that the export action accepts.

If the index screen already uses `table_preferences_hidden_fields(...)` for saved filter/sort UI state, keep that form submission separate from the export button and pass only the params that the export action actually needs. Hidden fields are a way to submit saved filter/sort params through a normal search form; the export form is still a host-app-owned request with its own accepted params. Rails Table Preferences owns the saved table preference payload; the host app still owns which query params are valid for export and whether saved params or user-entered params win when both are present.

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
  value_extractors = {
    "order_no" => ->(order) { order.order_no },
    "customer_name" => ->(order) { order.customer_name },
    "amount" => ->(order) { order.amount }
  }

  csv_string = CSV.generate do |csv|
    csv << export_payload["headers"]

    scoped_orders.find_each do |order|
      csv << export_payload["export_keys"].map do |key|
        value_extractors.fetch(key.to_s).call(order)
      end
    end
  end

  send_data csv_string, filename: "orders.csv"
end
```

This example intentionally keeps file generation, value extraction, and authorization policy in the host app. Rails Table Preferences only provides ordered column metadata and the selected preset name.

## How to use each payload key

- `headers`: write the exported header row in the same order the user sees in the table.
- `columns`: use when export values need metadata such as `export_key`, `label`, `group`, or visibility state.
- `column_keys`: use when the export layer needs the ordered display/preference keys for serializer mapping, SELECT whitelists, or downstream report builders keyed to the table surface. This list stays based on each column's `key`; it does not switch to `export_key` when export metadata is present.
- `export_keys`: use when the export layer only needs the ordered value-extraction keys. This list uses each column's `export_key` when present and falls back to the display/preference `key`.

When the host app already has a serializer or report object keyed by the displayed table columns, `column_keys` is often the smallest integration surface. When value extraction needs a different method or attribute, use `export_keys` directly or read `export_key` from each `columns` entry when extra metadata is needed.

Do not treat `column_keys` or `export_keys` as permission checks by themselves. Both arrays come from the table preference surface. The host app should still apply an export allowlist, serializer, or policy-aware extractor before reading values.

## Direct object usage

You can use the helper object directly outside controllers:

```ruby
payload = RailsTablePreferences::ExportPayload.call(
  settings: settings,
  columns: columns
)

payload["column_keys"] # display/preference keys
payload["export_keys"] # value-extraction keys
```

The direct object and controller helper return the same payload keys.

For direct object usage, treat `columns`, `column_keys`, `export_keys`, and `headers` as the export source of truth. They are built from the current column definitions and saved display preferences, so stale saved column keys are not reintroduced into the ordered export column list. The returned `settings` value is the normalized settings snapshot and may still include saved filter, sort, or column entries for keys that no longer exist in the current `columns` list.

Do not pass the direct object's `settings` snapshot straight into a host-app search layer as if it were controller params. If an export action needs saved filter/sort params, use `rails_table_preference_params(...)`, `rails_table_preference_merged_params(...)`, or `table_preferences_params(...)` with the same `columns` and adapter policy that the list action uses.

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

`include_hidden: true` only changes how the saved visibility preference is applied to the export payload. It applies to `columns`, `column_keys`, `export_keys`, and `headers` using the same filtered and ordered column list. It is not an authorization bypass and it does not make every hidden column safe to export.

Before exporting hidden or sensitive columns, keep this decision in the host application:

- maintain an allowlist or policy for exportable column keys before calling `public_send`, serializers, or report builders
- treat hidden columns as a display preference, not as a sensitivity marker
- exclude sensitive columns even when they are visible in the table unless the current user and export action are allowed to receive them
- document or test whether `include_hidden: true` is available to all users, admin-only users, or only specific export flows

## Export keys

Use `export_key` when the display/preference key differs from the export method or attribute. Helper-defined columns can declare it directly:

```ruby
columns = [
  table_preferences_column(
    :customer_name,
    label: "得意先名",
    export_key: :customer_display_name
  )
]
```

Hash column definitions can use the same metadata key:

```ruby
columns = [
  {
    key: :customer_name,
    label: "得意先名",
    export_key: :customer_display_name
  }
]
```

Then export code can read the ordered value-extraction keys directly:

```ruby
export_payload["column_keys"]
# => ["customer_name"]

export_payload["export_keys"]
# => ["customer_display_name"]
```

For integrations that need labels, groups, visibility, or other per-column metadata, use the equivalent value on each column entry:

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

For a one-line CSV header, `export_payload["headers"]` is usually enough. For an Excel or report export that needs grouped headers, read `export_payload["columns"]` so the host app can combine `group` metadata with the value-extraction key for each column:

```ruby
grouped_columns = export_payload["columns"].map do |column|
  group = column["group"] || {}

  {
    group_key: group["key"],
    group_label: group["label"],
    header: column["label"],
    value_key: column["export_key"] || column["key"]
  }
end

# Example shape for a host-app Excel/report builder:
# [
#   {
#     group_key: "customer",
#     group_label: "得意先情報",
#     header: "得意先名",
#     value_key: "customer_display_name"
#   }
# ]
```

The example above is only metadata preparation. The host application still owns the spreadsheet or report library, cell merging, blank group handling, value extraction, and policy-aware export allowlist.

## Responsibility boundary

Rails Table Preferences owns:

- resolving saved table preferences
- filtering hidden columns unless `include_hidden: true`
- ordering export columns according to saved display order
- returning labels and metadata
- converting saved filter/sort settings into params when the controller-param helpers are used

The host application owns:

- authorization
- deciding which request params an export action accepts
- deciding whether saved filter/sort params or user-entered request params win
- query execution
- CSV/Excel/report file generation
- formatting values
- deciding whether hidden columns should be exportable
- maintaining the allowlist or policy for exportable columns
- deciding whether sensitive columns should ever be selected or rendered
- testing export actions that use `include_hidden: true`
