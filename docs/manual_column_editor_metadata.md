# Manual column editor metadata

Manual table columns can declare cell editor metadata with `table_preferences_column(..., editor: ...)`. This gives custom table partials the same metadata entrypoint that resource table profiles already have through `TableProfile.editor(...)` and `column(..., editor: ...)`.

## Basic usage

```ruby
@preference_columns = [
  table_preferences_column(
    :status,
    label: "Status",
    editor: :select
  )
]
```

`editor: true` records the default text editor metadata. A string or symbol records a `type` value. A hash keeps richer renderer metadata:

```ruby
table_preferences_column(
  :status,
  label: "Status",
  editor: {
    type: :rails_fields_kit,
    method: :status,
    options: { helper: :enum_select }
  }
)
```

Objects that respond to `to_table_cell_editor` can also be used, matching the metadata object pattern used by richer form helper integrations.

## Rendering boundary

`table_preferences_cell_editor(form:, record:, column:)` reads the normalized `editor` metadata and calls the configured `editor_renderers` registry with the existing renderer contract:

- `form`
- `record`
- `method`
- `editor`
- `column`
- `view_context`

Rails Table Preferences owns the column metadata shape and renderer lookup. The host app owns the renderer registration, concrete form helper, final table partial layout, form submission, validation, authorization, persistence, and any inline editing workflow.

## Profile parity

Use profile metadata when the table is convention-first:

```ruby
class OrdersTableProfile < RailsTablePreferences::TableProfile
  model Order

  column :status, editor: { type: :rails_fields_kit, method: :status }
end
```

Use manual column metadata when the host app already assembles the column list by hand:

```ruby
columns = [
  table_preferences_column(:status, label: "Status", editor: { type: :rails_fields_kit, method: :status })
]
```

Both paths feed the same `table_preferences_cell_editor(...)` renderer lookup. Neither path adds a bundled save flow, authorization policy, or full inline editing framework.
