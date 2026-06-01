# Resource table cell hooks

Default `resource_table_for` and `tree_resource_table_for` partials keep the cell markup intentionally small while exposing stable data hooks for light host-app styling.

## Built-in row data attributes

Each non-empty flat `resource_table_for` body row includes:

- `data-rails-table-preferences-resource-row="true"`: marks a record row rendered by the default resource table partial.

Empty-state rows do not include this hook. This keeps record-row selectors separate from the existing empty message markup.

```html
<tr data-rails-table-preferences-resource-row="true">
  <td data-rails-table-preferences-column-key="status">active</td>
</tr>
```

Use this hook for light host-app CSS or system test selectors that need to target default record rows without replacing the bundled partial.

```css
.orders-table [data-rails-table-preferences-resource-row="true"] {
  vertical-align: top;
}
```

The row hook intentionally does not expose record id, model name, row index, authorization state, or business-specific status. Add those in a custom partial when the host app needs identity-aware behavior or row-specific presentation.

## TreeView row ownership

`tree_resource_table_for` keeps the built-in cell hooks, but it does not emit the flat-table row hook on TreeView rows. The surrounding `<tr>` markup, hierarchy controls, indentation, and expansion behavior are owned by the TreeView renderer; the Rails Table Preferences row partial only renders the visible cells for each TreeView item.

This is an intentional parity difference. Adding `data-rails-table-preferences-resource-row="true"` from Rails Table Preferences would require changing the TreeView row rendering contract, which is outside this gem's resource table helper boundary.

Use these paths instead:

- Use `data-rails-table-preferences-column-key` and `data-rails-table-preferences-filter-type` for column-level styling inside TreeView resource table cells.
- Use TreeView-level hooks or a custom TreeView row partial when the host app needs row-level CSS, system test selectors, or identity-aware presentation.
- Keep record id, model name, row index, authorization state, and business-specific status out of the generic Rails Table Preferences hooks.

## Built-in cell data attributes

Each non-empty resource table body cell includes:

- `data-rails-table-preferences-column-key`: the normalized column key, matching the header and saved table state metadata.
- `data-rails-table-preferences-filter-type`: the column filter metadata `type`, when the column has filter metadata.

For inferred Active Record columns, filter types come from the existing resource column metadata. Typical values are `text`, `number`, `date`, `boolean`, `select`, and `association`.

```html
<td
  data-rails-table-preferences-column-key="status"
  data-rails-table-preferences-filter-type="select"
>
  active
</td>
```

Use these hooks when the host app only needs small CSS adjustments such as aligning numeric columns, muting association labels, or styling boolean/select values as lightweight badges.

```css
.orders-table [data-rails-table-preferences-filter-type="number"] {
  text-align: right;
}

.orders-table [data-rails-table-preferences-filter-type="boolean"] {
  font-weight: 600;
}
```

## Responsibility boundary

The data hooks describe table rows and column metadata; they do not add built-in badges, enum colors, alignment rules, row colors, authorization state, or business-specific value formatting. Keep complex presentation in a profile `display` formatter or a custom partial.

If a column has no filter metadata, `data-rails-table-preferences-filter-type` is omitted instead of emitting an empty value. This keeps selectors explicit and avoids treating unknown metadata as a stable styling contract.

Tree resource tables keep the existing cell hooks, but TreeView owns the surrounding row markup. Do not assume the flat-table row hook is present in TreeView rows; use TreeView-level hooks or a custom TreeView row partial when row ownership matters.
