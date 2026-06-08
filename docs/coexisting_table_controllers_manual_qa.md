# Coexisting table controllers manual QA

Use this focused checklist when a host application mounts Rails Table Preferences on the same table root as one or more host-owned Stimulus controllers.

This page is a companion checklist for [Table data attribute merge boundary](table_data_attributes.md), not a primary docs-index catalog entry. Keep it outside package verification required paths unless it is promoted from nearby checklist to packaged public entry point; `docs/table_data_attributes.md` is the required package entrance for this boundary.

The goal is to confirm the attribute boundary, not to test the host controller implementation. Row selection, analytics, inline editing, bulk actions, and surrounding toolbar behavior remain host-app responsibilities.

## Setup surface

Create or choose a representative list screen where the rendered table root includes both the host controller token and `rails-table-preferences`:

```erb
<%= table_preferences_table_tag(
  table_key: :orders,
  columns: @table_columns,
  data: { controller: "orders-table row-selection", turbo_frame: "orders-frame" },
  class: "table"
) do %>
  ...
<% end %>
```

The exact host controller names do not matter. Prefer names that match the real screen, such as `orders-table`, `row-selection`, `analytics-table`, or `inline-edit-table`.

## Checklist

- [ ] Inspect the table root and confirm the host controller token is still present.
- [ ] Confirm `rails-table-preferences` appears exactly once in `data-controller`.
- [ ] Confirm generic host `data-*` attributes, such as `data-turbo-frame`, `data-role`, or analytics hooks, are still present.
- [ ] Confirm gem-owned values such as `data-rails-table-preferences-table-key-value`, `data-rails-table-preferences-settings-value`, and `data-rails-table-preferences-columns-value` come from the Rails Table Preferences helper arguments, not from host HTML overrides.
- [ ] Hide or reorder one managed column and confirm the Rails Table Preferences behavior still targets only cells with matching `data-rails-table-preferences-column-key` values.
- [ ] Exercise one host-owned behavior, such as row selection, analytics logging, inline edit affordance, or a bulk-action selection marker, and confirm it still uses host-owned attributes or controller state.
- [ ] Save and reload the preset, then confirm host-owned attributes or unmanaged columns are not removed by the saved table preference state.
- [ ] Trigger one filter, sort, resize, or apply action and confirm host-owned buttons, links, and inputs inside the table do not accidentally become Rails Table Preferences controls.

## Boundary notes

- Rails Table Preferences owns the `data-rails-table-preferences-*` runtime values it emits.
- The host app owns the meaning and behavior of any non-prefixed `data-*` attributes and additional controller tokens.
- If a host controller needs to react to preference changes, listen to the documented lifecycle events rather than reading private controller state.
- If a screen cannot keep this boundary with the bundled helper, use a custom partial or helper-free DOM contract instead of adding a host-controller integration framework to Rails Table Preferences.