# Active filter button cue

This note covers the bundled active-filter button cue added by the default stylesheet. It is a small visual affordance layered on top of the existing accessible state.

## What the bundled CSS provides

When a filter is active, the generated filter button keeps its compact text while the controller continues to expose state through `aria-pressed`, `aria-expanded`, `title`, and `aria-label`.

The default stylesheet also makes `.rails-table-preferences-filter-button--active` visible without relying on color alone:

- bold button text
- underline with a slightly heavier thickness and offset
- an inset `currentColor` boundary around the compact button

These cues are intentionally simple so host applications can override them in their copied stylesheet or app theme.

## What host applications still own

Host applications still own the final visual treatment in their design system. Before release, check the active filter button in the real table theme at desktop and narrow widths, including forced-colors or high-contrast modes when those are part of the support target.

If the active cue becomes too strong, too subtle, or visually conflicts with nearby sort and resize controls, override the active class in the host app rather than changing filter semantics.

## Manual QA checklist

- Active filter buttons remain distinguishable from inactive filter buttons without relying only on color.
- The button still exposes `aria-pressed="true"` while the filter is active.
- The active condition summary remains available through `title` or `aria-label`.
- The inset boundary does not overlap nearby sort indicators, resize handles, or header text at narrow widths.
- Host-app custom colors preserve enough contrast for the active cue.
