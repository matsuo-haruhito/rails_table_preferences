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

```ruby
display :customer_name do |order|
  order.customer&.name || "Unassigned"
end
```

## HTML safety and escaping

Formatter return values are presentation results that flow into Rails view rendering. A plain `String` should be treated as text content, not as an instruction to render raw HTML. If a cell needs a badge, link, icon wrapper, or other HTML output, return a value from Rails view helpers such as `view.tag.*` or `view.link_to` so the host app is making the HTML-safe boundary explicit through the normal Rails view contract.

```ruby
cell :status do |order, _column, view|
  view.tag.span(order.status_label, class: "status-badge status-badge--#{order.status}")
end
```

```ruby
display :customer do |order, view|
  view.link_to order.customer.name, view.customer_path(order.customer)
end
```

Do not use formatter blocks as an authorization, redaction, or route-policy shortcut. When a formatter returns a link or component-like fragment, the host app still owns the target route, permission check, sensitive-field redaction, CSS classes, and any design-system conventions behind that output.

## Association and query boundaries

Formatters may read associations or call helpers, but they do not move eager loading ownership into Rails Table Preferences. When a formatter reads `order.customer.name` or similar association data, preload that association in the host app relation and keep the formatter focused on presentation.

For PR or release evidence, record one representative query-log check or existing N+1 guard result for rows that use association-reading formatters. The manual QA guide keeps this as a smoke check so projects can confirm the relation stays preloaded without adding automatic preload behavior to this gem.

When no formatter is configured, `table_preferences_value(record, column)` falls back to the default value resolver for attributes, enum labels, boolean labels, and time-like values. That default fallback is separate from formatter result handling.
