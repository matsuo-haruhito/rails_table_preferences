# Editor entrypoint affordances

This note covers small browser checks for the packaged `rails_table_preferences/controller` entrypoint. The copied base controller remains the escape hatch for host applications that want to own their editor markup or interaction model directly.

## Column search

The package entrypoint adds a lightweight column search field before the generated editor rows. It filters the rendered editor row list by column label, key, or group text. Hidden rows remain in the DOM so applying or saving settings does not drop columns that are temporarily filtered out of view.

Search is an editor navigation affordance, not a column visibility filter. A no-results search only means every editor row is temporarily hidden in the editor surface; applying, saving, or saving as new should still assemble settings from all editor rows. Clear the search before reviewing the visible row list, but do not treat the no-results state as a request to save a zero-column table.

Use the bundled column search field when checking a table with many columns:

- search by a visible column label and confirm only matching rows remain visible
- search by a column key or group word when labels are similar
- clear the search and confirm every editor row returns
- apply or save while a search is active and confirm columns hidden by the search are not removed from the saved settings
- apply or save while the search has no results and confirm the saved settings still keep the full column set after clearing the search or reloading the preset

## Row move buttons

The package entrypoint also adds small up/down buttons beside each editor row. These buttons are a visible alternative to dragging rows and a quicker path than editing numeric order values by hand.

Use the row up/down buttons during browser QA:

- move a middle row up and down, then apply and confirm the table order changes
- confirm the first visible row disables the up button and the last visible row disables the down button
- filter the editor rows and confirm movement is limited to the visible filtered rows
- confirm the numeric order inputs update after each move
- confirm async preset actions still disable the generated editor controls while the request is busy

## Reset affordance

The package entrypoint keeps the bundled reset action tied to the existing editor status region. When the current editor draft already matches the table default settings, the reset button is disabled so the control does not look like a meaningful no-op. After a successful local reset, the status region announces the reset result with `rails_table_preferences.editor.reset_status` copy.

Use the reset action during browser QA:

- open an editor in its default state and confirm the reset button is disabled
- change visibility, order, width, truncate, filter, or sort state and confirm reset becomes available
- reset the editor and confirm the table returns to default settings, the reset button disables again, and the status region announces the reset result
- confirm the existing visible reset helper still explains that unsaved editor changes are discarded and defaults are restored

## Existing checklist routing

Use this note together with the existing checklist entries rather than as a replacement for them:

- `docs/manual_qa.md` section 4 already covers display preference behavior, order input fallback, narrow editor rows, and saved metadata after apply/save/reload/reset flows.
- `docs/manual_qa.md` section 16 already covers accessibility baseline checks for focus order, async busy disabling, numeric order fallback, touch/narrow viewport fallback, and keyboard-only reordering.
- `docs/manual_qa.md` section 18 already covers browser and layout checks for narrow widths, editor input overlap, and reachable column controls.
- `docs/accessibility.md` covers the package-entrypoint-only column search and row move controls, including accessible labels, filtered-row preservation, first/last/hidden/busy disabled states, and narrow-width checks.

`spec/javascript/rails_table_preferences_entrypoint_spec.rb` also includes a behavior-level Node check for the package entrypoint. It verifies that search hides rows without removing them from editor settings, row movement is constrained to visible filtered rows, numeric order inputs are refreshed after a move, existing filters/sorts are preserved, and busy state disables every generated move button.

`spec/javascript/rails_table_preferences_reset_feedback_spec.rb` guards the package entrypoint reset feedback surface: the editor root exposes reset result copy, reset completion uses the bundled status region, and the reset affordance is synchronized with the current default-state draft.

When this package entrypoint is changed, record in the PR comment or sign-off note which of those checklist areas were actually run. If browser access is not available, say that explicitly and rely on behavior-level entrypoint specs plus source-level guards until a human or browser-capable environment can complete the visual check.

## Boundary

These controls do not change table preference storage, query adapters, saved payload shape, authorization, or server-side behavior. They only adjust the package entrypoint editor surface and the default stylesheet. Host applications using a copied controller can copy the same idea or keep their custom editor behavior unchanged.
