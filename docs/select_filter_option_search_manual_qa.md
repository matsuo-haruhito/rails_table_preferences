# Select filter option search manual QA

Use this focused note when a PR touches the bundled static `select` filter option search or uses that behavior as review evidence.

This note is about the in-panel search field that appears when a static select filter has many rendered options. It does not add remote option loading, dependent select behavior, autocomplete, virtualized options, or a new filter panel layout.

## Scope

Use this note for static `select` filters whose options are rendered in the filter panel by Rails Table Preferences.

Do not use this note as proof for host-owned async widgets, remote search endpoints, authorization-aware option lists, or copied/custom select components. Those surfaces remain host app responsibilities.

## Representative smoke

- [ ] Open a filter panel for a static select filter with enough options to show the in-panel search field.
- [ ] Select at least one option, then search for text that does not match that selected option.
- [ ] Confirm the selected option remains visible while unselected non-matching options are hidden.
- [ ] Confirm an unselected option that matches by label or value remains visible.
- [ ] Change the selected option, search again, and confirm the visibility updates without keeping stale selected state visible.

## Boundary checks

- [ ] Saved filter values still use the existing `settings.filters` shape.
- [ ] Adapter params and query execution remain host-app owned.
- [ ] Remote option loading, dependent select behavior, and autocomplete are not introduced.
- [ ] Source inspection is not reported as rendered browser evidence when the PR acceptance criteria require a screenshot or browser-capable review.

## Evidence to record

Record the following in the PR body or review comment:

- representative table or demo screen
- selected option used for the non-matching search
- matching unselected option used for comparison
- whether the check was rendered in a browser, covered by a focused JavaScript/source spec, or handed off for browser-capable review
- any skipped remote/dependent select checks and why they were outside scope
