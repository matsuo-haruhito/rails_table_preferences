# Resource table empty messages

`resource_table_for` and `tree_resource_table_for` render the default `rails_table_preferences.resource_table.empty` copy when the records collection is empty.

Use `empty_message:` when a table needs a short, table-specific plain text message without copying the bundled partial:

```erb
<%= resource_table_for @orders, empty_message: "Change the search filters" %>
<%= tree_resource_table_for @projects, empty_message: "No matching projects" %>
```

The option is intentionally narrow:

- it changes only the empty cell text
- it is escaped like normal ERB output
- it is not forwarded as a table HTML attribute
- it does not change the empty row colspan, table caption, editor placement, filters, sorts, or saved settings payload

Use a custom `partial:` instead when the empty state needs richer markup, action buttons, permission-specific explanations, onboarding copy, or a host-app blank slate component. Rails Table Preferences keeps those product and authorization decisions in the host application.
