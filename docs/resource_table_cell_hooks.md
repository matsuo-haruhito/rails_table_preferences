# Resource table cell hooks

Default `resource_table_for` and `tree_resource_table_for` partials keep the cell markup intentionally small while exposing stable data hooks for light host-app styling.

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

The data hooks describe the column metadata; they do not add built-in badges, enum colors, alignment rules, or business-specific value formatting. Keep complex presentation in a profile `display` formatter or a custom partial.

If a column has no filter metadata, `data-rails-table-preferences-filter-type` is omitted instead of emitting an empty value. This keeps selectors explicit and avoids treating unknown metadata as a stable styling contract.

Tree resource tables use the same row-cell hooks as flat resource tables. Tree indentation, hierarchy controls, and row expansion remain owned by TreeView.
