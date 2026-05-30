# Resource table formatter contract

Resource table profiles can customize cell presentation with `display`, `cell`, or `column(..., &block)` formatters. These formatters are presentation hooks only: query behavior, authorization, eager loading, and route availability remain the host application's responsibility.

## Formatter arity

`RailsTablePreferences::ValueResolver` calls a formatter based on its arity:

- arity 1 receives `record`
- arity 2 receives `record, view_context`
- arity 3 or more receives `record, column, view_context`

Use one argument when the formatter only needs the row object:

```ruby
display :customer_name do |order|
  order.customer_name.upcase
end
```

Use two arguments when the formatter needs Rails view helpers:

```ruby
display :customer_id do |order, view|
  view.link_to order.customer.name, view.customer_path(order.customer)
end
```

Use three arguments when the formatter also needs the normalized column metadata:

```ruby
cell :status do |order, column, view|
  view.tag.span(order.status, class: "status status--#{column.fetch("key")}")
end
```

If a formatter returns `nil`, Rails Table Preferences treats that `nil` as the presentation result. Formatter exceptions are not rescued by the value resolver; keep host-app formatting code small and make any fallback behavior explicit in the formatter itself.

When no formatter is configured, `table_preferences_value(record, column)` falls back to the default value resolver for attributes, enum labels, boolean labels, and time-like values.
