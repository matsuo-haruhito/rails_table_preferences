# Manual table scroll wrappers

`table_preferences_table_tag(...)` can render the same lightweight scroll wrapper used by resource table helpers when a hand-written table needs a dedicated horizontal scroller.

Use `scroll_wrapper: true` only when the table should own horizontal overflow, such as fixed or pinned column screens that can be wider than the viewport.

```erb
<%= table_preferences_table_tag(
  table_key: :orders,
  columns: columns,
  scroll_wrapper: true,
  wrapper_options: {
    class: "orders-table-scroll",
    data: { controller: "orders-scroll" },
    aria: { label: "Orders table scroll area" }
  },
  class: "orders-table"
) do %>
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="order_no">Order no</th>
      <th data-rails-table-preferences-column-key="customer_name">Customer</th>
    </tr>
  </thead>
<% end %>
```

The helper keeps table attributes and wrapper attributes separate:

- `class:`, `id:`, `data:`, and `aria:` passed to `table_preferences_table_tag` stay on the `<table>`.
- `wrapper_options:` applies only to the outer `<div>`.
- the wrapper always includes `rails-table-preferences-resource-table-scroll` and appends any host class.
- `scroll_wrapper:` defaults to `false`, so existing manual table markup is unchanged unless the option is enabled.

Rails Table Preferences owns the metadata and stable wrapper hook. The host app still owns final overflow styling, sticky offset polish, focus and z-index checks, and any RTL or right-pinned column behavior.
