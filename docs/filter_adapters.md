# Filter adapters

Rails Table Preferences may provide Excel-like filter UI in a future version, but it should not become a general-purpose query builder.

The preferred boundary is:

- Rails Table Preferences owns filter UI state, saved filter conditions, saved sorts, presets, and normalized params.
- Host applications or existing gems own ActiveRecord query execution, joins, authorization, database-specific behavior, and business rules.

This lets the gem work alongside tools such as Ransack, Datagrid, Filterrific, or a host application's own search objects.

## Neutral filter format

Saved settings should remain gem-neutral:

```json
{
  "columns": [
    {
      "key": "customer_name",
      "visible": true,
      "order": 30,
      "width": 240,
      "truncate": 20
    }
  ],
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
      "operator": "lteq",
      "value": "2026-01-31"
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

The saved format should not use Ransack predicates, Datagrid filter names, Filterrific scope names, or application-specific SQL concepts directly.

## Ransack adapter

The initial adapter is a pure params converter. It does not require Ransack as a gem dependency and does not execute searches itself.

```ruby
filters = {
  customer_name: { operator: :contains, value: "山田" },
  status: { operator: :in, values: ["未出荷", "出荷済"] }
}

sorts = [
  { key: :delivery_date, direction: :desc }
]

ransack_params = RailsTablePreferences::Adapters::Ransack.to_params(
  filters: filters,
  sorts: sorts
)

# => {
#   "customer_name_cont" => "山田",
#   "status_in" => ["未出荷", "出荷済"],
#   "s" => ["delivery_date desc"]
# }

@q = Order.ransack(ransack_params)
@orders = @q.result
```

Supported operator mapping:

| Neutral operator | Ransack predicate |
| --- | --- |
| `contains` | `cont` |
| `not_contains` | `not_cont` |
| `equals` | `eq` |
| `not_equals` | `not_eq` |
| `starts_with` | `start` |
| `ends_with` | `end` |
| `in` | `in` |
| `not_in` | `not_in` |
| `gt` | `gt` |
| `gteq` | `gteq` |
| `lt` | `lt` |
| `lteq` | `lteq` |
| `blank` | `blank` |
| `present` | `present` |
| `true` | `true` |
| `false` | `false` |

## Datagrid and Filterrific direction

Datagrid and Filterrific should be handled as adapter targets later, but Rails Table Preferences should avoid deeply controlling their internals.

Preferred direction:

```ruby
datagrid_params = RailsTablePreferences::Adapters::Datagrid.to_params(filters: filters, sorts: sorts)
filterrific_params = RailsTablePreferences::Adapters::Filterrific.to_params(filters: filters, sorts: sorts)
```

The host application should still decide:

- which Datagrid class or Filterrific configuration to use
- which scopes or joins are allowed
- which fields are searchable by the current user
- how business-specific conditions are applied

## Non-goals

Rails Table Preferences should not become:

- a generic ActiveRecord query builder
- a Ransack replacement
- a Datagrid replacement
- a Filterrific replacement
- a DataTables replacement
- an automatic join inference system
- an authorization system

The gem's role is to provide a good table preference UX and normalized saved UI state that can be handed to existing search layers.
