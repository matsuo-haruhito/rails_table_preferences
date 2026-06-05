# Header drag reorder

The bundled package controller enables table-header drag reorder for managed header cells by default. Managed headers are `<th>` elements with `data-rails-table-preferences-column-key`, and normal columns keep the existing lightweight drag behavior without extra configuration.

Host applications that render interactive header content can opt out one column at a time through column metadata:

```erb
<%= table_preferences_column(:account_help, label: "Help", draggable: false) %>
```

When `draggable: false` is present in the current column definition, the package controller leaves that header cell non-draggable and does not install the table-column drag class or drag event listeners for that header. Other managed headers still keep normal reorder behavior.

Use this for columns whose header owns a link, menu, help trigger, or another host-app interaction where drag reorder would make the hit area too aggressive. Keep resize handles, filter buttons, and sortable header clicks on their existing surfaces; `draggable: false` only disables direct table-header drag reorder for that column.

Notes:

- Omit `draggable:` to keep the existing default behavior.
- `draggable: false` does not hide the column from the editor and does not disable editor-row drag reorder.
- The option does not add table-wide drag disable behavior. If the whole table needs a different reorder policy, use a copied or replacement controller.
- The copied controller remains replaceable; host applications that maintain their own copied controller should port this behavior explicitly if they want the same opt-out contract outside the package entrypoint.
