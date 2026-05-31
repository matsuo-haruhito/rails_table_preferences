# Filter metadata

Rails Table Preferences can carry filter and sort metadata without taking responsibility for executing database searches.

This document describes the neutral metadata that can be attached to column definitions and saved settings. Search execution should remain in the host application or in a search gem such as Ransack, Datagrid, or Filterrific.

## Column metadata

Columns can declare filter metadata, sortability, and display metadata such as overflow behavior:

```ruby
columns = [
  table_preferences_column(
    :customer_name,
    label: "得意先名",
    filter: { type: :text, operators: %i[contains equals blank] },
    sortable: true,
    overflow: :ellipsis
  ),
  table_preferences_column(
    :status,
    label: "状態",
    filter: { type: :select, options: ["未出荷", "出荷済", "保留"] },
    sortable: true
  ),
  table_preferences_column(
    :delivery_date,
    label: "納品日",
    filter: { type: :date, operators: %i[equals gteq lteq between] },
    sortable: true
  ),
  table_preferences_column(
    :note,
    label: "備考",
    filter: true,
    overflow: :wrap
  )
]
```

You can also omit `label:` when the label is resolved through `i18n_key:` or a database column comment via `model:`.

Shorthands are available:

```ruby
table_preferences_column(:customer_name, label: "得意先名", filter: true)                         # { "type" => "text" }
table_preferences_column(:status, label: "状態", filter: :select)                                 # { "type" => "select" }
table_preferences_column(:customer_name, label: "得意先名", overflow: :truncate)                   # overflow: "ellipsis"
table_preferences_column(:internal_note, label: "内部メモ", filter: false, overflow: :wrap)        # no filter metadata, wrapped text
```

The metadata is serialized into `columns_json` so the front-end can decide which filter UI to render and how to apply static display behavior such as overflow. It is not a query definition.

For bundled `select` filters, `options:` accepts scalar values or label/value hashes. Scalar options keep the historical behavior: the same value is used for the HTML `<option value>`, visible option text, saved filter value, and adapter params.

Use `{ value:, label: }` when the saved/search value should be stable machine data and the UI should show a human label:

```ruby
table_preferences_column(
  :status,
  label: "状態",
  filter: {
    type: :select,
    values_param: :statuses,
    options: [
      { value: "pending", label: "未出荷" },
      { value: "shipped", label: "出荷済" },
      { value: "hold", label: "保留" }
    ]
  }
)
```

The bundled controller renders the label as option text, stores the `value` in saved filter settings, restores multi-select selected state by `value`, and passes that `value` through the ControllerParams / Ransack adapters. It does not infer labels from enums, load remote options, or change host-app query execution.

## Bundled default filter operators

When `operators:` is omitted, the bundled controller chooses a default operator list from the filter type. `filter: true` and `filter: { type: :text }` both use the default text row.

| Filter type | Default operators |
| --- | --- |
| `text` / default | `contains`, `equals`, `starts_with`, `ends_with`, `blank`, `present` |
| `number` | `equals`, `gteq`, `lteq`, `gt`, `lt`, `blank`, `present` |
| `date` | `equals`, `gteq`, `lteq`, `between`, `blank`, `present` |
| `select` | `in`, `not_in`, `blank`, `present` |
| `boolean` | `true`, `false`, `blank`, `present` |

Passing `operators:` replaces the default list instead of appending to it. The order in the array is the order shown in the bundled filter panel, so use a short explicit list when the host app search layer only supports a subset of predicates.

The bundled controller has labels for additional operators such as `not_contains` and `not_equals`, but those operators are not included in the default text set. Host apps may opt in by passing them through `operators:`, but Rails Table Preferences still only saves neutral filter state and shapes adapter params. Query execution, unsupported predicate handling, joins, and authorization remain the responsibility of the host application or search adapter.

If the host app only needs to change bundled filter/sort wording such as `絞り込み`, `条件`, `開始`, `終了`, or sort labels, treat that as a copy-override concern rather than metadata design. See [Accessibility baseline](accessibility.md) and [JavaScript controller notes](javascript_controller.md).

Supported overflow values are:

- `:ellipsis` or `:truncate`: single-line hidden overflow with `...`
- `:clip`: single-line hidden overflow without `...`
- `:wrap`: multi-line wrapping
- `:nowrap`: single-line overflow without clipping

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

The bundled header click UI is intentionally single-sort. Each header click replaces `sorts` with either one sort entry for the clicked column or an empty array when the cycle clears the sort. The array shape is still neutral so adapters, imports, exports, and host-app customizations can read the same saved settings shape; it is not a promise that the bundled controller provides multi-column sort interactions.

Host applications that need multi-sort UI should provide that interaction in their own controller or copied controller and write the resulting ordered sort entries into `settings["sorts"]`. Rails Table Preferences can still carry and adapt the neutral array, but the default header click behavior only manages one active sort at a time.

The header also receives `aria-sort` and a minimal visual indicator:

- ascending: `▲`
- descending: `▼`
- none: no indicator

The sort click handler ignores clicks from filter buttons, resize handles, buttons, inputs, selects, and textareas so it does not interfere with filtering, resizing, or other controls. Double-clicking a resize handle auto-fits column width and stores the result as normal width state; it does not change filter or sort state.

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
    label: "得意先名",
    filter: { type: :text, param: :search_word },
    overflow: :ellipsis
  ),
  table_preferences_column(
    :status,
    label: "状態",
    filter: { type: :select, values_param: :statuses, options: ["未出荷", "出荷済"] }
  ),
  table_preferences_column(
    :delivery_date,
    label: "納品日",
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

`operator_param` is not emitted for every operator. The ControllerParams adapter currently maps operators as follows:

- `between` writes the `from` and `to` values to `from_param` / `to_param`, or to `from_<param>` / `to_<param>` fallbacks. It does not emit `operator_param`.
- `gteq` and `gt` write the scalar value to `from_param`, or to the `from_<param>` fallback. They do not emit `operator_param`.
- `lteq` and `lt` write the scalar value to `to_param`, or to the `to_<param>` fallback. They do not emit `operator_param`.
- `in` and `not_in` write an array to `values_param`, or to the base `param` fallback. They do not emit `operator_param`.
- `blank`, `present`, `true`, and `false` emit the operator as the signal because they do not carry a separate value. They use `operator_param` when provided, otherwise `<param>_operator`.
- Other scalar operators such as `contains` and `equals` write the scalar value to `param`. They also emit `operator_param` only when that metadata key is present.

If an existing `search(params)` implementation expects an operator name for every condition, normalize that expectation in host-app code or provide metadata/UI conventions that match the adapter output. Rails Table Preferences keeps this adapter as a params-shaping helper; it does not execute the query or infer a host application's predicate semantics.

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
      "values": ["pending", "shipped"]
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

When `ignored_columns`, per-column `ignored: true`, or unresolved labels are used, saved filters and sorts for those columns are also removed from `settings_json`.

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
  "statuses" => ["pending", "shipped"],
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
