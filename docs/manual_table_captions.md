# Manual table captions

`table_preferences_table_tag(...)` supports an optional `caption:` argument for helper-free or manual table markup that still uses the Rails Table Preferences controller contract.

Use it when the table needs a short semantic name and the host app does not already render a native caption inside the table block:

```erb
<%= table_preferences_table_tag(
  table_key: :orders,
  columns: @table_columns,
  caption: "Orders"
) do %>
  <thead>
    <tr>
      <th data-rails-table-preferences-column-key="customer_name">Customer</th>
    </tr>
  </thead>
  <tbody>
    ...
  </tbody>
<% end %>
```

The helper renders the caption as the first child of the generated `<table>`, before the block content, and escapes plain caption text through normal Rails tag escaping.

Do not also render a second `<caption>` inside the block when `caption:` is passed. If the host app needs richer caption markup, complex explanatory text, or a custom placement, leave `caption:` unset and keep the host-owned caption or surrounding instructions in the block or page template.

The default `resource_table_for` and `tree_resource_table_for` caption behavior remains unchanged. This page only covers the manual `table_preferences_table_tag(...)` path.
