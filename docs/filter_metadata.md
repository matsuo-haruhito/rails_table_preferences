# Filter metadata

Rails Table Preferences can carry filter and sort metadata without taking responsibility for executing database searches.

This document describes the neutral metadata that can be attached to column definitions and saved settings. Search execution should remain in the host application or in a search gem such as Ransack, Datagrid, or Filterrific.

## Column metadata

Columns can declare filter metadata and sortability:

```ruby
columns = [
  table_preferences_column(
    :customer_name,
    model_name: :order,
    filter: { type: :text, operators: %i[contains equals blank] },
    sortable: true
  ),
  table_preferences_column(
    :status,
    model_name: :order,
    filter: { type: :select, options: ["未出荷", "出荷済", "保留"] },
    sortable: true
  ),
  table_preferences_column(
    :delivery_date,
    model_name: :order,
    filter: { type: :date, operators: %i[equals gteq lteq between] },
    sortable: true
  )
]
```

Shorthands are available:

```ruby
table_preferences_column(:customer_name, filter: true)    # { "type" => "text" }
table_preferences_column(:status, filter: :select)        # { "type" => "select" }
table_preferences_column(:internal_note, filter: false)   # no filter metadata
```

The metadata is serialized into `columns_json` so the front-end can decide which filter UI to render. It is not a query definition.

## Sort UI

When `sortable: true` is set, the default Stimulus controller lets users click the table header to cycle through sort states:

1. no sort -> ascending
2. ascending -> descending
3. descending -> clear sort

The current sort state is saved in the neutral `sorts` array:

```json
{
  "sorts": [
    {
      "key": "delivery_date",
      "direction": "desc"
    }
  ]
}
```

The header also receives `aria-sort` and a minimal visual indicator:

- ascending: `▲`
- descending: `▼`
- none: no indicator

The sort click handler ignores clicks from filter buttons, resize handles, buttons, inputs, selects, and textareas so it does not interfere with filtering, resizing, or other controls.

## Mapping to existing controller params

Many Rails applications already expose list screens through methods such as:

```ruby
@warehouse_stocks = WarehouseStock
  .search(params)
  .order_by(params[:sort])
```

For these applications, add plain param names to the column metadata:

```ruby
columns = [
  table_preferences_column(
    :customer_name,
    filter: { type: :text, param: :search_word }
  ),
  table_preferences_column(
    :status,
    filter: { type: :select, values_param: :statuses, options: ["未出荷", "出荷済"] }
  ),
  table_preferences_column(
    :delivery_date,
    filter: { type: :date, from_param: :from_date, to_param: :to_date },
    sortable: true
  )
]
```

Supported plain-param metadata:

| Metadata key | Purpose |
| --- | --- |
| `param` | Scalar filter param name |
| `values_param` | Multi-value filter param name |
| `from_param` | Lower-bound/range start param name |
| `to_param` | Upper-bound/range end param name |
| `operator_param` | Optional param that receives the selected operator |
| `sort_param` | Sort key name passed as the sort value |

## Saved filter settings

Saved filter conditions use a neutral format:

```json
{
  "filters": {
    "customer_name": {
      "operator": "contains",
      "value": "山田"
    },
    "status": {
      "operator": "in",
      "values": ["未出荷", "出荷済"]
    },
    "delivery_date": {
      "operator": "between",
      "from": "2026-01-01",
      "to": "2026-01-31"
    }
  },
  "sorts": [
    {
      "key": "delivery_date",
      "direction": "desc"
    }
  ]
}
```

`SettingsNormalizer` normalizes:

- symbol keys to string keys
- `predicate` to `operator`
- scalar `values` to arrays
- sort aliases `column`/`dir` to `key`/`direction`
- sort direction casing to `asc` or `desc`

Invalid filters without an operator are dropped. Invalid sorts without a key, without a direction, or with a direction other than `asc` or `desc` are dropped.

## Ignored columns

When `ignored_columns` or per-column `ignored: true` is used, saved filters and sorts for those columns are also removed from `settings_json`.

This prevents hidden columns from being reintroduced through an old saved preference.

## Search adapters

The neutral format can be converted for an existing search layer.

### ControllerParams adapter

Use this adapter for existing controllers that accept plain params:

```ruby
preference = current_user.table_preferences.find_by!(table_key: "warehouse_stocks", name: "default")
settings = preference.settings

preference_params = RailsTablePreferences::Adapters::ControllerParams.to_params(
  filters: settings["filters"],
  sorts: settings["sorts"],
  columns: columns
)

merged_params = params.to_unsafe_h.merge(preference_params)

@warehouse_stocks = WarehouseStock
  .search(merged_params)
  .order_by(merged_params["sort"])
```

Example output:

```ruby
{
  "search_word" => "山田",
  "statuses" => ["未出荷", "出荷済"],
  "from_date" => "2026-01-01",
  "to_date" => "2026-01-31",
  "sort" => "-delivery_date"
}
```

Descending sorts are prefixed with `-` by default. Ascending sorts use the key as-is. Use `sort_param:` to change the top-level sort param name:

```ruby
RailsTablePreferences::Adapters::ControllerParams.to_params(
  filters: settings["filters"],
  sorts: settings["sorts"],
  columns: columns,
  sort_param: :order
)
```

### Ransack adapter

Use this adapter when the host application already uses Ransack:

```ruby
ransack_params = RailsTablePreferences::Adapters::Ransack.to_params(
  filters: settings["filters"],
  sorts: settings["sorts"]
)

@q = Order.ransack(ransack_params)
@orders = @q.result
```

Rails Table Preferences does not execute the query itself. Host applications remain responsible for authorization, joins, allowed searchable fields, and business-specific filtering.
