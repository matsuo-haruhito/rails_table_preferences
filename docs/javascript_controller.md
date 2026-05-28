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

## Bundled filter panel contract

The default filter panel stays intentionally lightweight.

- The triggering filter button owns `aria-expanded` and `aria-controls` while its panel is open.
- Opening the panel moves focus into the first bundled filter field.
- Pressing `Escape` closes the panel and returns focus to the triggering filter button.
- Clicking outside still closes the panel.
- Scroll and viewport resize also close the panel so the body-mounted panel does not drift away from its header context.
- The bundled controller does not add a full popover library, focus trap, or modal dialog abstraction.

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

When the page also renders the bundled editor or preset select, pass `data-rails-table-preferences-name-value` too so the helper-free table root stays aligned with the current preset name.

Example manual root wiring:

```erb
<div
  data-controller="rails-table-preferences"
  data-rails-table-preferences-table-key-value="<%= @table_key %>"
  data-rails-table-preferences-name-value="<%= @table_preference_name %>"
  data-rails-table-preferences-collection-url-value="<%= @table_preference_collection_url %>"
  data-rails-table-preferences-url-value="<%= @table_preference_url %>"
  data-rails-table-preferences-columns-value="<%= @table_columns.to_json %>"
  data-rails-table-preferences-settings-value="<%= @table_preference_settings.to_json %>">
  <table class="table">
    <thead>
      <tr>
        <th data-rails-table-preferences-column-key="order_no">受注番号</th>
        <th data-rails-table-preferences-column-key="customer_name">得意先名</th>
        <th>備考</th>
        <th>操作</th>
      </tr>
    </thead>
    <tbody>
      <% @orders.each do |order| %>
        <tr>
          <td data-rails-table-preferences-column-key="order_no"><%= order.order_no %></td>
          <td data-rails-table-preferences-column-key="customer_name"><%= order.customer_name %></td>
          <td><%= truncate(order.note, length: 40) %></td>
          <td><%= link_to "詳細", order_path(order) %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>
```

Notes:

- `order_no` and `customer_name` are managed by Rails Table Preferences because both header and body cells expose matching column keys.
- `備考` and `操作` stay fully host-app-owned because they do not expose `data-rails-table-preferences-column-key`.
- The URL values above assume the default mount path. If the host app mounts the engine elsewhere, change both URLs to the mounted path that serves `/preferences/:table_key`.
- The example intentionally reuses `@table_preference_settings` from `rails_table_preference_settings(...)` and the same column definitions the host app passes to `table_preferences_editor(...)`.

## Bundled editor copy override path

The bundled editor resolves most visible helper copy before the controller runs, in the ERB partial, through locale keys under `rails_table_preferences.editor`.

Representative keys include:

- `action_hint`
- `read_only_preset_hint`
- `loading_status`
- `saved_status`
- `deleting_failed_status`
- `reset_hint`

In practice that means:

- filter/sort button labels can be overridden per controller root through `data-rails-table-preferences-*-label-value`
- bundled helper/status/reset wording is usually better changed through host-app locale entries
- copied ERB or a replacement controller is only needed when the host app wants different markup, per-screen copy rules, or a custom status surface

For a concrete locale example and the accessibility surfaces those keys feed, see [Accessibility baseline](accessibility.md).

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

The project includes source-level specs for the Stimulus controller and package entrypoints, plus one narrow browser/system smoke for a demo-shaped screen. The source-level specs are not a replacement for broader browser/system coverage, but they still guard important invariants around the controller and package entrypoints.

Important invariants include:

- Japanese default UI labels remain available
- table cell effects are table-scoped
- filters and sorts are preserved by editor actions
- header controls do not accidentally trigger sort or drag
- sortable behavior is limited to `sortable: true` columns
- document listeners and detached filter panels are cleaned up
- `rails_table_preferences/controller` continues to export the bundled controller for Vite and other JS bundlers
