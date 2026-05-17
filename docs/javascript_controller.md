# JavaScript controller notes

The bundled Stimulus controller is intentionally small and replaceable. Host applications can use the packaged entrypoint, edit the copied file, or replace it with another controller registered as `rails-table-preferences`.

For import paths and Vite / `app/frontend` setup, see [JavaScript entrypoints](javascript_entrypoints.md).

## Responsibilities

The default controller currently handles:

- editor row rendering
- preset loading, saving, creating, deleting, and resetting
- column visibility
- column order from editor row drag-and-drop
- direct table header column reordering
- column width resizing
- text truncation application
- filter button and filter panel UI
- saved filter condition updates
- sortable header click UI
- sort indicators and `aria-sort`

## Event boundaries

The table header may support multiple interactions at once:

- header click: sort toggle when the column is sortable
- header drag: column order change
- right-edge handle drag: column width resize
- filter button click: filter panel open/close

The controller keeps these separate through `shouldIgnoreHeaderAction(target)`. Header sort and drag actions should ignore:

- resize handles
- filter buttons
- buttons
- inputs
- selects
- textareas

The sort handler also ignores active drag and resize operations.

## Table-only application rule

Column display effects must be applied only to cells inside the target table. This prevents editor rows from being affected when they use the same `data-rails-table-preferences-column-key` values as table cells.

The controller should use:

```js
const table = this.tableElement
return table.querySelectorAll(`[data-rails-table-preferences-column-key="${CSS.escape(key)}"]`)
```

It should not apply display, width, or truncation changes by querying the entire controller element.

## Saved column metadata rule

Current column definitions from the host application should remain authoritative for labels, filter metadata, and sortable metadata. Saved preference records may contain old column settings, so merge logic should preserve current definitions for:

- `label`
- `filter`
- `sortable`

Saved settings should only override user-owned state such as visibility, order, width, truncation, filters, and sorts.

## Filter and sort behavior

Filters and sorts update the in-memory `settingsValue` payload. Display-only settings can be applied to the current table immediately. Filter and sort execution usually requires the host application to run its own search query, reload, or submit a form.

Use the Ruby helpers and adapters for that part:

- `rails_table_preference_params`
- `rails_table_preference_merged_params`
- `table_preferences_params`
- `table_preferences_hidden_fields`
- `RailsTablePreferences::Adapters::ControllerParams`
- `RailsTablePreferences::Adapters::Ransack`

## Source-level safety specs

The project includes source-level specs for the Stimulus controller and package entrypoints. These are not a replacement for browser/system specs, but they guard important invariants while browser tests are not yet being run.

Important invariants include:

- Japanese default UI labels remain available
- table cell effects are table-scoped
- filters and sorts are preserved by editor actions
- header controls do not accidentally trigger sort or drag
- sortable behavior is limited to `sortable: true` columns
- document listeners and detached filter panels are cleaned up
- `rails_table_preferences/controller` continues to export the bundled controller for Vite and other JS bundlers
