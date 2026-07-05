# Rails Fields Kit bridge contract

This note defines the Rails Table Preferences side of a future Rails Fields Kit bridge. It is a docs/contract slice only. It does not add a runtime dependency, renderer implementation, or downstream adoption work.

Use this page with [Filter metadata](filter_metadata.md) and [Resource table adapters](resource_tables.md) when a host app wants Rails Table Preferences columns to carry metadata that Rails Fields Kit can render.

## Source-of-truth boundary

Rails Table Preferences is the source of truth for table-column preference state. A bridge should keep these responsibilities here:

- column keys and user-facing labels
- filter and editor metadata attached to a column
- saved filter state and saved sort state
- column visibility, order, width, overflow, fixed/pinned state, and export metadata
- adapter params derived from saved settings
- renderer registry lookup for filter/editor metadata types

Rails Fields Kit is the source of truth for the concrete form control rendering behind `rfk_*` helpers:

- `TableFilterInput` and `TableCellInput` metadata objects
- `TableMetadata` normalization and `TableRenderer` call specs
- rendered helper HTML, wrapper wiring, hints, errors, and accessibility wiring
- Tom Select lifecycle and native wrapper behavior for the rendered control

The host application remains the source of truth for:

- query execution and accepted query params
- authorization, scoping, and tenant rules
- persistence policy for table preference records
- remote option endpoints, selected-option preload policy, validation copy, retry UI, and visible success/error feedback
- pagination, sorting execution, exports, and business actions

## Metadata that may cross the bridge

Keep the first bridge small. Representative metadata that can cross from Rails Table Preferences column definitions to Rails Fields Kit rendering includes:

- text-like filters and native inputs
- select or enum-like filters where the saved value is still the table/query value
- token-search metadata where the host app owns parsing and execution
- cell editor metadata where the table column owns identity and the form helper owns rendering

Do not mirror the full Rails Table Preferences DSL into Rails Fields Kit. Column visibility, widths, saved presets, export metadata, adapter params, and query execution are not Rails Fields Kit rendering metadata.

## Dependency policy

Do not add a Rails Fields Kit dependency to Rails Table Preferences for this first slice. The current bridge should stay optional:

- Rails Table Preferences can carry renderer type names or Rails Fields Kit metadata objects when the host app provides them.
- Rails Fields Kit can normalize and render objects responding to `to_table_filter` or `to_table_cell_editor`.
- The host app wires the two gems together through renderer registration or custom partials.

A dedicated optional adapter can be considered only after the small metadata contract is stable. If that happens, split it into a separate issue and keep the mapping to a few representative cases such as text, select, token-search, and cell editor metadata.

## Non-goals for this issue

This issue does not add:

- a Rails Fields Kit runtime dependency
- a new public adapter module
- a renderer registry redesign
- full Rails Fields Kit helper invocation inside the bundled filter panel
- query execution, authorization, persistence policy, remote option loading, or selected-option preload behavior
- docs-portal Gemfile bumps, pinned SHA decisions, or downstream smoke tests
- TreeView, bulk action helper, or release train changes

## Follow-up handoff

After this contract is accepted, pass the boundary to the Rails Fields Kit side so it can decide whether the first route is still docs recipe / duck-typing or whether a separate optional adapter module is worth planning.

Downstream docs-portal adoption should remain separate. It should choose screens, pinned SHAs, and smoke evidence only after the RTP/RFK ownership split is stable.
