# JavaScript controller notes

The bundled Stimulus controller is intentionally small and replaceable. Host applications can use the packaged entrypoint, edit the copied file, or replace it with another controller registered as `rails-table-preferences`.

For import paths and Vite / `app/frontend` setup, see [JavaScript entrypoints](javascript_entrypoints.md).

## Responsibilities

The default controller currently handles:

- editor row rendering
- preset loading, saving, creating, deleting, and resetting
- a bundled dirty-state indicator for unsaved editor changes
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

## Minimal DOM contract for helper-free tables

When a host app keeps its own `<table>` markup, the bundled controller still works as long as the DOM contract stays intact.

- The controller root may be the `<table>` itself, or another element that contains the target `<table>`.
- When the root is not a table, the controller uses the first nested `<table>` as its target table.
- Managed headers and cells must expose matching `data-rails-table-preferences-column-key` values.
- Sort, filter, resize, reorder, and pinned-column behavior only apply to managed headers/cells inside that target table.
- Columns without `data-rails-table-preferences-column-key` stay under normal host-app control.

This is the supported path for server-rendered tables that come from an existing partial, Markdown/HTML rewrite, or another renderer that cannot directly use `table_preferences_table_tag(...)`.

## Manual root values when bypassing the table helper

If the host app mounts the controller root manually instead of using the bundled table helper, provide the same core values that the controller reads from normal helper output:

- `data-controller="rails-table-preferences"`
- `data-rails-table-preferences-table-key-value`
- `data-rails-table-preferences-collection-url-value`
- `data-rails-table-preferences-url-value`
- `data-rails-table-preferences-columns-value`
- `data-rails-table-preferences-settings-value`

Optional UI labels such as `data-rails-table-preferences-filter-label-value` and `data-rails-table-preferences-sort-asc-label-value` can also be overridden when the host app needs localized copy different from the defaults.

## Stable table_key guideline

Use a `table_key` that identifies the logical screen or template, not a transient record id, request param, or DOM-generated UUID.

Good examples:

- `orders_index`
- `document_markdown_preview`
- `admin_customer_exports`

Avoid keys that change per request or per row, because saved presets, column order, and width history are keyed to that value.

## Saved column metadata rule

Current column definitions from the host application should remain authoritative for labels, filter metadata, and sortable metadata. Saved preference records may contain old column settings, so merge logic should preserve current definitions for:

- `label`
- `filter`
- `sortable`

Saved settings should only override user-owned state such as visibility, order, width, truncation, filters, and sorts.

## Dirty-state indicator boundary

The bundled dirty-state indicator compares the current editor form state plus filter/sort state against the last loaded or saved preset payload.

This baseline intentionally stays lightweight:

- it shows only whether there are unsaved changes
- it does not render a detailed diff
- it clears when a preset is loaded, saved, created, or deleted through the bundled async flow
- host applications can replace it with richer inline feedback in copied views or a custom controller

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
- dirty-state messaging is available without changing preset persistence behavior
- filters and sorts are preserved by editor actions
- header controls do not accidentally trigger sort or drag
- sortable behavior is limited to `sortable: true` columns
- document listeners and detached filter panels are cleaned up
- `rails_table_preferences/controller` continues to export the bundled controller for Vite and other JS bundlers
