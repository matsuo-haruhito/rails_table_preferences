# Visual overview

This page gives a quick visual reference for the bundled demo surface before you copy the demo files into a host application.

The images below stay intentionally lightweight: one view centers on the bundled editor and scoped preset flow, and the other centers on grouped headers plus fixed-column context. Together they mirror the current docs entry points without implying host-app branding.

## Editor and scoped preset flow

![Bundled demo screen showing the preset editor, scope-aware preset choices, and a compact orders table preview.](images/visual-overview-editor-and-table.svg)

What this view highlights:

- the bundled editor layout above the table
- owner, shared, and role preset context without adding an admin UI
- visible column toggles, order controls, and width controls
- a compact table preview that keeps the preset choice tied to a realistic list screen

## Grouped headers and fixed-column context

![Bundled demo table state showing grouped customer and delivery headers alongside a fixed leading column.](images/visual-overview-filter-and-pinned-columns.svg)

What this view highlights:

- grouped header metadata rendered as host-app-owned table markup
- a fixed leading column that stays visually anchored while scanning
- active filter and sort context on user-facing columns
- the same business-table density used throughout the demo-oriented docs

## Notes

- The exact visual polish still comes from the host application after copying the ERB, CSS, or Stimulus controller.
- Use [Scoped presets](scoped_presets.md) and [Fixed columns and column groups](fixed_columns_and_groups.md) when you want the policy and markup details behind these overview states.
- Use the [Demo screen generator](demo.md) when you want to reproduce similar states inside a sandbox app and verify behavior in a real browser.
