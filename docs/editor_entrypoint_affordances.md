# Editor entrypoint affordances

This note covers small browser checks for the packaged `rails_table_preferences/controller` entrypoint. The copied base controller remains the escape hatch for host applications that want to own their editor markup or interaction model directly.

## Column search

The package entrypoint adds a lightweight column search field before the generated editor rows. It filters the rendered editor row list by column label, key, or group text. Hidden rows remain in the DOM so applying or saving settings does not drop columns that are temporarily filtered out of view.

Use the bundled column search field when checking a table with many columns:

- search by a visible column label and confirm only matching rows remain visible
- search by a column key or group word when labels are similar
- clear the search and confirm every editor row returns
- apply or save while a search is active and confirm columns hidden by the search are not removed from the saved settings

## Row move buttons

The package entrypoint also adds small up/down buttons beside each editor row. These buttons are a visible alternative to dragging rows and a quicker path than editing numeric order values by hand.

Use the row up/down buttons during browser QA:

- move a middle row up and down, then apply and confirm the table order changes
- confirm the first visible row disables the up button and the last visible row disables the down button
- filter the editor rows and confirm movement is limited to the visible filtered rows
- confirm the numeric order inputs update after each move
- confirm async preset actions still disable the generated editor controls while the request is busy

## Existing checklist routing

Use this note together with the existing checklist entries rather than as a replacement for them:

- `docs/manual_qa.md` section 4 already covers display preference behavior, order input fallback, narrow editor rows, and saved metadata after apply/save/reload/reset flows.
- `docs/manual_qa.md` section 16 already covers accessibility baseline checks for focus order, async busy disabling, numeric order fallback, touch/narrow viewport fallback, and keyboard-only reordering.
- `docs/manual_qa.md` section 18 already covers browser and layout checks for narrow widths, editor input overlap, and reachable column controls.
- `docs/accessibility.md` covers the bundled drag-and-drop fallback, busy-state disabling, locale-driven copy, and manual accessibility checks for keyboard-only reorder and narrow/touch flows.

When this package entrypoint is changed, record in the PR comment or sign-off note which of those checklist areas were actually run. If browser access is not available, say that explicitly and rely on source-level guards plus CI until a human or browser-capable environment can complete the visual check.

## Boundary

These controls do not change table preference storage, query adapters, saved payload shape, authorization, or server-side behavior. They only adjust the package entrypoint editor surface and the default stylesheet. Host applications using a copied controller can copy the same idea or keep their custom editor behavior unchanged.
