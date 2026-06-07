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

## Saved settings numeric boundary

Saved column settings keep only positive integers for `width`, `truncate`, and `order`. Numeric strings such as `"120"` are normalized to integers, while `0`, negative values, blanks, and malformed values are treated as missing and fall back to the column definition or default ordering behavior.

This defensive normalization applies to settings saved through the bundled editor and to compatible payloads written by host-app scripts or custom preference UIs. It prevents stale or hand-written settings from applying invalid widths or truncation hints while preserving existing positive values.

## Bundled editor boundary

The bundled editor currently lets users change visibility, order, width, and the numeric truncate hint. It does not render an overflow mode selector and does not expand the saved settings payload with a user-editable overflow field.

Treat `overflow:` / `default_overflow:` as column-definition metadata owned by the host app. If a screen needs user-editable overflow modes, keep that as a copied editor or custom controller extension so the host app can choose the UI density, saved payload shape, and interaction with `truncate` deliberately.

This boundary keeps narrow editor rows from gaining another control while preserving the existing precedence: saved column settings can change width and truncate values, and the current column definition still supplies the visual overflow mode.

## Visual evidence and PR smoke boundary

Use the generated demo or a representative host-app table when a PR needs rendered evidence for overflow behavior. The demo is the maintained quick check because it puts `wrap`, `nowrap`, and `ellipsis` columns on the same screen.

For docs-only changes that only describe the existing metadata contract, browser evidence is usually not required. Record the source files checked and point readers back to this guide, the demo manual checks, and the PR smoke matrix.

For UI, CSS, demo, or visual-reference changes that claim an overflow mode looks correct, record rendered evidence or leave an explicit browser-capable handoff. Good evidence names the screen, representative column, viewport or container width, overflow mode checked, and whether the check used the generated demo or a real host-app table.

Keep this evidence separate from editor configurability. The bundled editor still does not expose an overflow selector, and visual evidence for `:ellipsis`, `:clip`, `:wrap`, or `:nowrap` should not imply a new saved setting or user-editable overflow field.

## Example

```ruby
@table_columns = [
  table_preferences_column(:customer_name, label: "Customer", default_width: 240, overflow: :ellipsis),
  table_preferences_column(:note, label: "Note", default_width: 320, overflow: :wrap),
  table_preferences_column(:code, label: "Code", default_width: 120, overflow: :clip)
]
```

See [Quick start](quick_start.md#6-configure-overflow-behavior-when-needed) for the shortest end-to-end setup and [Demo screen generator](demo.md) for visual checks of wrap, nowrap, and ellipsis behavior.
