# Tree resource table empty message

`resource_table_for` and `tree_resource_table_for` both accept `empty_message:` when the bundled default partial renders an empty records state.

```erb
<%= resource_table_for @orders, empty_message: "No orders yet" %>

<%= tree_resource_table_for(
  @projects,
  parent_id_method: :parent_project_id,
  empty_message: "No projects yet"
) %>
```

The custom message is used only when the records collection is empty. If `empty_message:` is omitted or blank, both helpers keep the default `rails_table_preferences.resource_table.empty` fallback.

The all-hidden-columns state is separate. When records are present but every column is hidden, the default partial still renders `rails_table_preferences.resource_table.all_columns_hidden` instead of the empty records message.

Table HTML options such as `id`, `class`, `data`, and `aria` still belong to the `<table>`. `empty_message:` is consumed by the bundled partial and is not forwarded as a table HTML attribute.

Rails Table Preferences owns the small default copy hook. Host applications still own richer blank-slate layouts, calls to action, permission-specific wording, filter reset behavior, and any custom empty-state component.
