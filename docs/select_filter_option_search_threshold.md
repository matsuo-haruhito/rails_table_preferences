# Select Filter Option Search Threshold

The package entrypoint controller shows a small search input above bundled `select` filter options when the option list reaches the configured threshold.

By default the threshold is `8`, preserving the existing behavior: option lists with fewer than 8 items do not show the search input, and option lists with 8 or more items do.

Host apps that use the package entrypoint controller can adjust only this display threshold with the root Stimulus value:

```erb
<div
  data-controller="rails-table-preferences"
  data-rails-table-preferences-select-filter-option-search-threshold-value="12">
</div>
```

## Display Modes

The value is intentionally numeric so the package entrypoint keeps one small display contract:

| Goal | Threshold value | Behavior |
| --- | --- | --- |
| Default threshold display | omitted or `8` | Show the search input for option lists with 8 or more options. |
| Always show for non-empty lists | `0` or a negative number | Show the search input whenever the select has at least one option. |
| Effectively hide for ordinary lists | a value larger than the expected option count | Keep the search input hidden until the option list reaches that value. |

There is no separate boolean disable flag. If a host app wants to hide the search input for its ordinary bundled select filters, use a high threshold that is larger than those option lists. This keeps the setting separate from filter metadata, saved settings, adapter params, and query execution.

## Empty Results

When the search input is visible and the query matches no option, the package entrypoint shows a small no-results message next to the input. Selected options remain visible even if they do not match the query, so users can still see and clear the current selection.

If the query matches only the current selected option, the no-results message stays hidden because the visible selected option is a real match. If the query matches neither selected nor unselected options, the message can appear while the selected option remains visible as preserved context.

The message is exposed as a polite status cue for assistive technology when the empty state becomes visible.

The message is a package default copy and does not change option rendering, submitted values, saved settings, or query execution.

## Boundary

This value is package-entrypoint-only. It does not add filter metadata, change saved settings, change ControllerParams or Ransack adapter output, or affect query execution.

Invalid, blank, or non-numeric values fall back to `8`. Values are normalized to an integer with `Math.floor`, so `8.9` behaves as `8`.

Scalar select options and `{ value:, label: }` options keep their existing behavior: the visible label is used for option text, the value is saved/restored, and the search input filters against visible option text and value.

Keep remote option loading, async search, dependent selects, Select2-style widgets, query semantics, authorization, and validation policy in host-app code or a host-owned renderer.
