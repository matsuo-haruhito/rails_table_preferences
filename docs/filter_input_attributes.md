# Filter input attributes

Rails Table Preferences can render a few browser input attributes from neutral filter metadata in the package entrypoint controller.

This is a browser-affordance slice only. These values do not change saved filter settings, ControllerParams output, Ransack output, server-side validation, query execution, summaries, or authorization.

## Supported metadata

For bundled `number` and `date` filters, the package entrypoint controller passes these metadata keys through to generated value inputs:

| Metadata key | Rendered attribute | Applies to |
| --- | --- | --- |
| `min` | `min` | scalar value input and both `between` inputs |
| `max` | `max` | scalar value input and both `between` inputs |
| `step` | `step` | scalar value input and both `between` inputs |

`placeholder` remains supported for scalar `text`, `number`, and `date` value inputs. For `between`, use `from_placeholder` and `to_placeholder` so the lower and upper bound inputs can show different examples. The shared `min` / `max` / `step` metadata applies to both generated range inputs.

```ruby
table_preferences_column(
  :total_amount,
  label: "合計金額",
  filter: {
    type: :number,
    operators: %i[equals gteq lteq between],
    min: 0,
    max: 1_000_000,
    step: 100,
    placeholder: "10000"
  }
)

table_preferences_column(
  :delivery_date,
  label: "納品日",
  filter: {
    type: :date,
    operators: %i[equals gteq lteq between],
    min: "2026-01-01",
    max: "2026-12-31",
    step: 7,
    from_placeholder: "2026-04-01",
    to_placeholder: "2026-04-30"
  }
)
```

## Boundaries

The bundled controller escapes the attribute values before writing them into HTML. Blank values are omitted.

These attributes are not validation rules in Rails Table Preferences. Browsers may use them for native affordances, but host applications still own server-side validation, accepted query params, date/time interpretation, decimal precision, adapter semantics, and error messages.

`select`, `boolean`, blank/present operators, richer widgets, remote option loading, and third-party date or number widgets are outside this package-entrypoint attribute surface. Use host-owned custom filter HTML or a renderer registry mapping when a screen needs those behaviors.
