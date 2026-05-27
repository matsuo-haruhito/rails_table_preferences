# Visual overview

This page gives a quick visual reference for the bundled demo surface before you copy the demo files into a host application.

The images below stay intentionally lightweight, but they now mirror the current generated demo more closely: Japanese labels, the seeded shared preset `共有ビュー`, and the sample search/sort cues used throughout the demo docs. Use the generated demo screen as the behavioral source of truth and treat these images as a compact orientation aid.

## Editor and shared preset flow

![Bundled demo-aligned view showing the shared preset path, Japanese table labels, and the lightweight orders screen.](images/visual-overview-editor-and-table.svg)

What this view highlights:

- the bundled editor layout above the table
- the seeded `共有ビュー [shared]` path and the normal owner-facing editor state
- Japanese demo labels, status copy, and practical sample rows from the generated screen
- search-form and preset context staying tied to the same list screen

## Grouped headers and fixed-column context

![Demo-aligned table view showing grouped customer and delivery headers plus a fixed leading order column.](images/visual-overview-filter-and-pinned-columns.svg)

What this view highlights:

- grouped-header and pinned-column guidance using the same Japanese business-table vocabulary as the demo docs
- `東京` search and `納品日` sort cues that match the demo-oriented QA flow
- fixed/pinned metadata staying visible without implying that the gem owns final host-app markup
- the same dense list-screen posture used across the quick-start and maintenance docs

## Notes

- The generated demo screen remains the best place to verify actual behavior in a browser.
- Use [Scoped presets](scoped_presets.md) and [Demo screen generator](demo.md) for the seeded `共有ビュー` flow, and [Fixed columns and column groups](fixed_columns_and_groups.md) when you want the pinned/grouped markup details behind the second image.
- The exact visual polish still comes from the host application after copying the ERB, CSS, or Stimulus controller.
