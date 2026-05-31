# Select filter troubleshooting

Use this guide when a bundled `select` filter appears in the UI but the host application does not apply the selected values to the database query.

Rails Table Preferences stores filter UI state and can convert it to params, but the host application still owns query execution. The bundled controller also treats `select` filter `options:` as a scalar list: each option is both the submitted value and the visible label.

## Symptoms

- The filter panel shows the expected select options, but applying the filter does not change the records.
- The saved filter summary looks correct, but `search(params)` receives a different key than expected.
- A multi-value select filter saves values, but the host app search layer reads only a scalar param.
- A host app tries to pass `{ value:, label: }` option objects and expects separate submitted values and labels.

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

## Keep option values scalar

The bundled `select` filter currently expects scalar `options:` values:

```ruby
filter: { type: :select, options: ["未出荷", "出荷済", "保留"] }
```

Do not document object-shaped options as supported by the bundled controller today:

```ruby
# Not supported by the bundled select UI today
filter: { type: :select, options: [{ value: "open", label: "Open" }] }
```

If a host app needs separate machine values and human labels, keep that mapping in host-app code, provide a copied/custom controller or filter UI, or wait for a dedicated value/label pair feature. See [Filter metadata](filter_metadata.md) for the current scalar option contract.

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
- Keep `options:` scalar and translate values to labels outside the bundled select UI.
- Use `adapter: :ransack` when the target query layer is Ransack rather than a plain `search(params)` method.

See also [Controller integration](controller_integration.md), [Filter metadata](filter_metadata.md), and [Filter adapters](filter_adapters.md).
