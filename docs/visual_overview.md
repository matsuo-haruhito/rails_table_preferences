# Visual overview

This page gives a quick visual reference for the bundled demo surface before you copy the demo files into a host application.

The illustrations below are representative examples of the generated editor and table layout. They are meant to show the default UI coverage, not to prescribe host-app branding.

## Editor and preset flow

![Representative demo screen showing the preset editor above an orders table with pinned columns and active filters.](images/visual-overview-editor-and-table.svg)

What this view highlights:

- the bundled editor layout above the table
- saved preset selection and naming
- visible column toggles, order controls, and width controls
- a table view with a pinned leading column and active filter state

## Filter, sort, and fixed-column context

![Representative table state showing pinned order columns, active sort, and visible filter controls.](images/visual-overview-filter-and-pinned-columns.svg)

What this view highlights:

- sortable headers and a visible sort indicator
- filter controls attached to user-facing columns
- pinned columns that stay visually anchored at the left edge
- a realistic business-table density instead of an isolated widget mock

## Notes

- The exact visual polish comes from the host application after copying the ERB, CSS, or Stimulus controller.
- Use the [Demo screen generator](demo.md) when you want to reproduce these states inside a sandbox app and verify behavior in a real browser.
