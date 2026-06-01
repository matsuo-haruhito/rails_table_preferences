# Resource table cell hooks

Default `resource_table_for` and `tree_resource_table_for` partials keep the row and cell markup intentionally small while exposing stable data hooks for light host-app styling and system test selectors.

## Built-in row data attributes

Each non-empty flat `resource_table_for` body row includes a generic row marker:

- `data-rails-table-preferences-resource-row="true"`: the row is rendered for a record by the default flat resource table partial.

```html
<tr data-rails-table-preferences-resource-row="true">
  <td data-rails-table-preferences-column-key="status">active</td>
</tr>
```

Use this hook when the host app needs a stable selector for lightweight CSS or system tests that should apply to all rendered record rows.

```css
.orders-table [data-rails-table-preferences-resource-row="true"]:hover {
  background: var(--table-row-hover-background);
}
```

The row hook intentionally does not expose record ids, model names, row indexes, authorization state, or business-specific status. Keep identity-sensitive selectors and business styling in a custom partial or host-app-specific formatter.

Empty-state rows do not receive the record row hook.

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

The data hooks describe generic flat row presence and column metadata; they do not add built-in badges, enum colors, alignment rules, record identity, or business-specific value formatting. Keep complex presentation in a profile `display` formatter or a custom partial.

If a column has no filter metadata, `data-rails-table-preferences-filter-type` is omitted instead of emitting an empty value. This keeps selectors explicit and avoids treating unknown metadata as a stable styling contract.

Tree resource tables use the same cell hooks as flat resource tables. Tree row markup, indentation, hierarchy controls, and row expansion remain owned by TreeView, so TreeView-specific row selectors should come from TreeView or a custom tree row partial rather than the flat resource row hook.
