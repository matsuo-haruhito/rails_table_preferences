# Select filter troubleshooting

Use this guide when a bundled `select` filter appears in the UI but the host application does not apply the selected values to the database query.

Rails Table Preferences stores filter UI state and can convert it to params, but the host application still owns query execution. Package-entrypoint `select` filter `options:` can use scalar values or `{ value:, label: }` hashes. Copied/base controller screens should treat scalar options as the safe default unless the host app has ported the package entrypoint label/value normalization. In both cases, the saved value and adapter params remain host-app search inputs rather than a database query executed by Rails Table Preferences.

## Symptoms

- The filter panel shows the expected select options, but applying the filter does not change the records.
- The saved filter summary looks correct, but `search(params)` receives a different key than expected.
- A multi-value select filter saves values, but the host app search layer reads only a scalar param.
- A `{ value:, label: }` option displays the right label in the package entrypoint path, but the host app search layer still needs the machine value under a different param name.
- A copied/base controller screen shows unexpected object-shaped option text because label/value option normalization was not ported from the package entrypoint.
- A large static option list shows the package option-search input, but query results do not change after applying the selected values.

## Check the params contract

For plain controller params, declare the param names expected by the existing search method:

```ruby
columns = [
  table_preferences_column(
    :status,
    label: "状態",
    filter: {
      type: :select,
      options: ["未出荷", "出荷済", "保留"],
      param: :status,
      values_param: :statuses
    }
  )
]
```

When the saved operator is `in` or `not_in`, the ControllerParams adapter writes an array to `values_param` when present. If `values_param` is omitted, it falls back to the base `param`, or to the column key when `param` is also omitted.

That means this metadata:

```ruby
filter: { type: :select, options: ["open", "closed"], values_param: :states }
```

emits params like:

```ruby
{ "states" => ["open", "closed"] }
```

Without `values_param`, the same saved condition falls back to:

```ruby
{ "status" => ["open", "closed"] }
```

Make sure the host app's `search(params)` or equivalent query object reads the same key and accepts an array for multi-value conditions.

## Keep label/value options as display metadata

Use scalar options when the submitted value and visible label are the same:

```ruby
filter: { type: :select, options: ["未出荷", "出荷済", "保留"] }
```

Use `{ value:, label: }` when the saved/search value should be stable machine data and the UI should show a human label:

```ruby
filter: {
  type: :select,
  values_param: :statuses,
  options: [
    { value: "pending", label: "未出荷" },
    { value: "shipped", label: "出荷済" },
    { value: "hold", label: "保留" }
  ]
}
```

The package entrypoint controller renders `label` as option text, stores `value` in saved filter settings, restores multi-select selected state by `value`, and passes that `value` through the ControllerParams / Ransack adapters. The copied/base controller path currently keeps scalar select option rendering as the safe default, so copied controller host apps should either keep scalar options or explicitly port the package entrypoint label/value option normalization. Neither path infers enum labels, loads remote options, or translates submitted values into a host-app query.

If the UI looks correct but results do not change, check the host app search layer first. The fix is usually to align `values_param:` with the query object, teach the query object to accept the emitted array, or keep a host-owned mapping between machine values and database predicates.

For long static option lists, see [Select filter option search threshold](select_filter_option_search_threshold.md). The package option-search input only filters already-rendered options in the panel; it does not perform remote search, change saved settings shape, or execute the database query.

## Confirm the host app applies the params

After calling `rails_table_preference_params`, merge the returned params into the same object the host app query layer already reads:

```ruby
preference_params = rails_table_preference_params(
  table_key: :orders,
  columns: columns
)

merged_params = params.to_unsafe_h.merge(preference_params)

@orders = Order.search(merged_params)
```

If the select UI works but the result set does not change, log or inspect `preference_params` first. Rails Table Preferences does not execute the database query, so the fix is usually one of these:

- Add `values_param:` because the host app expects a different array param name.
- Update the host app search method to read the emitted array param.
- Use `{ value:, label: }` only for stable machine values and human labels on the package entrypoint path, or after a copied controller has ported the same normalization.
- Use `adapter: :ransack` when the target query layer is Ransack rather than a plain `search(params)` method.
- Keep remote option loading, dependent selects, and richer widgets in host-owned renderer or custom partial code.

See also [Controller integration](controller_integration.md), [Filter metadata](filter_metadata.md), and [Filter adapters](filter_adapters.md).
