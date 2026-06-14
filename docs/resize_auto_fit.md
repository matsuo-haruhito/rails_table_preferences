# Resize and auto-fit guidance

The bundled controller provides a small resize surface for server-rendered tables. It owns the generated header resize handles, drag width updates, and double-click auto-fit behavior. Host applications still own final table layout, scroll containers, sticky column polish, and any custom resize algorithm.

## Controller root values

When the host app uses the bundled table helper, the default values are enough for most screens. When a host app mounts the controller manually or needs to tune dense table layouts, these optional root values can be provided on the controller element:

| Root value | Default | Purpose |
| --- | ---: | --- |
| `data-rails-table-preferences-resize-handle-width-value` | `10` | Width in pixels for the generated right-edge resize hit area. Increase it if users struggle to grab the handle in dense headers. |
| `data-rails-table-preferences-resize-auto-fit-padding-value` | `24` | Extra pixels added around measured content when double-click auto-fit calculates a column width. |
| `data-rails-table-preferences-resize-auto-fit-min-width-value` | `40` | Lower bound for the auto-fit result when the column does not define `min_width`. |
| `data-rails-table-preferences-resize-auto-fit-max-width-value` | `640` | Upper bound for the auto-fit result when the column does not define `max_width`. |

Example manual override:

```erb
<div
  data-controller="rails-table-preferences"
  data-rails-table-preferences-table-key-value="orders"
  data-rails-table-preferences-resize-handle-width-value="14"
  data-rails-table-preferences-resize-auto-fit-padding-value="32"
  data-rails-table-preferences-resize-auto-fit-min-width-value="56"
  data-rails-table-preferences-resize-auto-fit-max-width-value="720">
  ...
</div>
```

Keep these values layout-focused. They tune the bundled handle and auto-fit measurements; they do not change saved preference semantics, filter/sort behavior, pinned-column offset logic, or host-app search execution.

## Initial width markup in manual tables

`table_preferences_column(..., default_width:)` is column metadata for the controller and default settings. It is not a server-rendered `<colgroup>` contract, and `table_preferences_table_tag(...)` does not generate initial width markup inside the table body.

For manual table screens, the host app still owns structural table markup such as `<colgroup>`, `<thead>`, and `<tbody>`. If a dense table needs stable first-paint widths before JavaScript applies saved settings, render that markup in the helper block or table CSS owned by the host app:

```erb
<%= table_preferences_table_tag(table_key: :orders, columns: columns) do %>
  <colgroup>
    <col style="width: 120px">
    <col style="width: 240px">
    <col style="width: 140px">
  </colgroup>
  ...
<% end %>
```

After the controller connects, saved widths, editor changes, resize drag, and auto-fit continue to use the normal Rails Table Preferences settings path. Treat host-owned `<colgroup>` or CSS widths as initial layout hints, not as a replacement for saved width settings.

## Column width boundaries

Columns can define positive integer `min_width` and `max_width` metadata when one column needs a different width boundary from the table-wide auto-fit defaults.

```ruby
column :memo, label: "Memo", min_width: 120, max_width: 480
```

Column-specific boundaries are authoritative for that column:

- drag resizing clamps to the column boundary, falling back to a `40px` lower bound only when the column does not define `min_width`
- double-click auto-fit clamps to `min_width` / `max_width` when present, and otherwise falls back to the root auto-fit min/max values
- editor width input values are normalized through the same column boundary before settings are applied or saved
- previously saved widths that exceed the column boundary are rendered and pinned-offset-calculated with the clamped width

Only positive integers are emitted as column width boundary metadata. Blank, zero, negative, or non-numeric values are omitted.

## Manual QA focus

Use the [Manual QA checklist](manual_qa.md) as the release and host-app sign-off source. For resize changes, pay particular attention to these existing checks:

- resize a column using the header resize handle
- double-click a resize handle and confirm the column auto-fits to visible content
- confirm the resize hit area is easy enough to grab
- confirm hover and keyboard focus affordances do not shift header text, filter buttons, or sort indicators
- check narrow desktop widths, long labels, long values, horizontal scroll, and fixed/pinned columns

If the host app uses custom table CSS or scroll containers, record the chosen root values, any column-specific boundaries, and any host-owned initial width markup in host-app documentation so future UI changes can keep the same assumptions.
