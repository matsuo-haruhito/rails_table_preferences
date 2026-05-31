# Resize and auto-fit guidance

The bundled controller provides a small resize surface for server-rendered tables. It owns the generated header resize handles, drag width updates, and double-click auto-fit behavior. Host applications still own final table layout, scroll containers, sticky column polish, and any custom resize algorithm.

## Controller root values

When the host app uses the bundled table helper, the default values are enough for most screens. When a host app mounts the controller manually or needs to tune dense table layouts, these optional root values can be provided on the controller element:

| Root value | Default | Purpose |
| --- | ---: | --- |
| `data-rails-table-preferences-resize-handle-width-value` | `10` | Width in pixels for the generated right-edge resize hit area. Increase it if users struggle to grab the handle in dense headers. |
| `data-rails-table-preferences-resize-auto-fit-padding-value` | `24` | Extra pixels added around measured content when double-click auto-fit calculates a column width. |
| `data-rails-table-preferences-resize-auto-fit-min-width-value` | `40` | Lower bound for the auto-fit result. |
| `data-rails-table-preferences-resize-auto-fit-max-width-value` | `640` | Upper bound for the auto-fit result. |

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

## Manual QA focus

Use the [Manual QA checklist](manual_qa.md) as the release and host-app sign-off source. For resize changes, pay particular attention to these existing checks:

- resize a column using the header resize handle
- double-click a resize handle and confirm the column auto-fits to visible content
- confirm the resize hit area is easy enough to grab
- confirm hover and keyboard focus affordances do not shift header text, filter buttons, or sort indicators
- check narrow desktop widths, long labels, long values, horizontal scroll, and fixed/pinned columns

If the host app uses custom table CSS or scroll containers, record the chosen root values in host-app documentation so future UI changes can keep the same assumptions.