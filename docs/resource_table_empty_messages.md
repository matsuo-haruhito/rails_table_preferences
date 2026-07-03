# Resource table empty messages

Use `empty_message:` when the bundled `resource_table_for` partial should show short table-specific copy for an empty collection:

```erb
<%= resource_table_for(
  @orders,
  empty_message: "No orders match this search"
) %>
```

Reach for this guide after [Resource table adapters](resource_tables.md) when the model inference and empty collection setup are already correct, but the default empty-table copy should be clearer for a specific screen.

When `empty_message:` is omitted or blank, the partial keeps using `I18n.t("rails_table_preferences.resource_table.empty", default: "No records to display")`.

`empty_message:` is plain text copy for the bundled empty table cell. It is rendered through normal ERB escaping, so do not use it for links, buttons, onboarding CTAs, or authorization-aware business actions. Use a custom resource table partial when the empty state needs richer markup or behavior.
