# Datetime and time filter browser attributes

The package entrypoint controller renders `datetime`, `datetime-local`, and `time` filter metadata with native browser inputs:

- `datetime` and `datetime-local` use `input[type="datetime-local"]`.
- `time` uses `input[type="time"]`.

These filter types can pass `min`, `max`, and `step` metadata through to the generated input as browser affordance attributes:

```ruby
table_preferences_column(
  :shipped_at,
  label: "Shipped at",
  filter: {
    type: :datetime,
    min: "2026-01-01T09:00",
    max: "2026-12-31T18:00",
    step: 900
  }
)

table_preferences_column(
  :dispatch_time,
  label: "Dispatch time",
  filter: {
    type: :time,
    min: "09:00",
    max: "18:00",
    step: 300
  }
)
```

For scalar operators such as `equals`, `gteq`, and `lteq`, the attributes are added to the single value input. For `between`, the same attributes are added to both the lower-bound and upper-bound inputs so the browser controls stay consistent.

Blank metadata is omitted, and attribute values are HTML-escaped before rendering. These attributes do not change saved filter settings, adapter output, validation, timezone handling, or query execution. The host application remains responsible for interpreting browser-local datetime strings, validating accepted ranges, and building the database query.

Manual QA for this slice:

- Open a `datetime` or `datetime-local` filter and confirm the input remains a native `datetime-local` control.
- Open a `time` filter and confirm the input remains a native `time` control.
- Confirm `min`, `max`, and `step` are present for scalar and `between` inputs when metadata is set.
- Confirm omitted or blank `min`, `max`, and `step` metadata does not render empty attributes.
- Confirm applying the filter still saves neutral string values and leaves timezone conversion to the host app.
