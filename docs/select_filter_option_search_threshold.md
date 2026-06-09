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

## Empty Results

When the search input is visible and the query matches no unselected option, the package entrypoint shows a small no-results message next to the input. Selected options remain visible even if they do not match the query, so users can still see and clear the current selection.

The message is a package default copy and does not change option rendering, submitted values, saved settings, or query execution.

## Boundary

This value is package-entrypoint-only. It does not add filter metadata, change saved settings, change ControllerParams or Ransack adapter output, or affect query execution.

Invalid, blank, or non-numeric values fall back to `8`. Values are normalized to an integer with `Math.floor`. A threshold of `0` or lower means any non-empty select option list can show the search input; a very large value can effectively keep the search input hidden for ordinary option lists.

Scalar select options and `{ value:, label: }` options keep their existing behavior: the visible label is used for option text, the value is saved/restored, and the search input filters against visible option text and value.

Keep remote option loading, async search, dependent selects, Select2-style widgets, query semantics, authorization, and validation policy in host-app code or a host-owned renderer.
