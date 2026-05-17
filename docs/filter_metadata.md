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

The neutral format can be converted for a search gem. The first adapter is Ransack:

```ruby
ransack_params = RailsTablePreferences::Adapters::Ransack.to_params(
  filters: settings["filters"],
  sorts: settings["sorts"]
)

@q = Order.ransack(ransack_params)
@orders = @q.result
```

Rails Table Preferences does not execute the query itself. Host applications remain responsible for authorization, joins, allowed searchable fields, and business-specific filtering.
