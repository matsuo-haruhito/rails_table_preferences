# Column overflow metadata

Use `overflow:` or `default_overflow:` on `table_preferences_column(...)` when a column needs a display mode for text that is wider than the saved or default column width.

Prefer the canonical values below in new examples and host-app code:

| Value | Result |
| --- | --- |
| `:ellipsis` | Single-line hidden overflow with an ellipsis. |
| `:clip` | Single-line hidden overflow without an ellipsis. |
| `:wrap` | Multi-line wrapping. |
| `:nowrap` | Single-line text without clipping. |
| `nil` | No explicit overflow mode from Rails Table Preferences. |

`overflow:` and `default_overflow:` feed the same column metadata. Use `overflow:` in new code unless an older integration already uses `default_overflow:` for clarity.

## Backward-compatible aliases

The column definition normalizes a few convenience and compatibility aliases before exposing the column metadata to the editor/controller:

| Input | Normalized overflow |
| --- | --- |
| `true` | `"ellipsis"` |
| `:truncate`, `:truncated`, `:ellipsis`, `"truncate"`, `"truncated"`, `"ellipsis"` | `"ellipsis"` |
| `:clip`, `:clipped`, `"clip"`, `"clipped"` | `"clip"` |
| `:wrap`, `:wrapped`, `"wrap"`, `"wrapped"` | `"wrap"` |
| `:nowrap`, `"nowrap"` | `"nowrap"` |
| `false`, `:none`, `"none"`, `nil`, or an unknown value | `nil` |

Keep aliases when maintaining older copied column definitions, but write new docs and examples with `:ellipsis`, `:clip`, `:wrap`, `:nowrap`, or `nil` so the intended display mode is easy to read.

## Relationship to `default_truncate:`

`default_truncate:` is numeric truncation metadata. It controls the default character-length hint stored for a column.

`overflow:` / `default_overflow:` controls the visual overflow mode. For example, `overflow: :ellipsis` describes single-line clipped display with an ellipsis, while `default_truncate: 40` describes the starting truncation length.

Use both only when the screen needs both pieces of metadata. For most new column definitions, prefer `overflow:` for the display mode and add `default_truncate:` only when the host app still needs a default truncation length.

## Example

```ruby
@table_columns = [
  table_preferences_column(:customer_name, label: "Customer", default_width: 240, overflow: :ellipsis),
  table_preferences_column(:note, label: "Note", default_width: 320, overflow: :wrap),
  table_preferences_column(:code, label: "Code", default_width: 120, overflow: :clip)
]
```

See [Quick start](quick_start.md#6-configure-overflow-behavior-when-needed) for the shortest end-to-end setup and [Demo screen generator](demo.md) for visual checks of wrap, nowrap, and ellipsis behavior.
