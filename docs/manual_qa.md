# Manual QA checklist

Run the checks that match the product surface you actually use. Most applications do not need every section below.

## 1. Installation and boot

- [ ] Run the generator.
- [ ] Run the migration.
- [ ] Mount the engine.
- [ ] Register the Stimulus controller.
- [ ] Confirm no duplicate Stimulus registration exists.
- [ ] Confirm the host app boots without JavaScript console errors.

## 2. Basic editor behavior

- [ ] The editor opens.
- [ ] The editor lists the expected columns.
- [ ] Visible columns can be toggled.
- [ ] Column order can be changed.
- [ ] Column widths can be changed.
- [ ] Truncation mode changes apply as expected.
- [ ] Overflow mode changes apply as expected.
- [ ] Reset returns to the default state.
- [ ] Saving persists the current settings.
- [ ] Reloading restores the saved settings.

## 3. Presets

- [ ] Shared presets appear when expected.
- [ ] Role presets appear when expected.
- [ ] Organization presets appear when expected.
- [ ] Shared presets are read-only for non-owners.
- [ ] Saving while a shared preset is selected creates or updates an owner preset.
- [ ] Default preset resolution follows owner -> role -> organization -> shared.
- [ ] Deleting a preset removes it from the selector.
- [ ] Read-only fallback behavior appears when expected.

## 4. Filter panel

- [ ] Filter panel opens.
- [ ] Text filter values persist through save/reload.
- [ ] Select filter values persist through save/reload.
- [ ] Date-range filter values persist through save/reload.
- [ ] Neutral filters do not accidentally narrow results.
- [ ] Closing the panel does not lose saved state.

## 5. Existing search form integration

- [ ] Add `table_preferences_hidden_fields(...)` to a GET form.
- [ ] Confirm saved filters appear as ordinary controller params.
- [ ] Confirm saved sort state appears as the expected sort param.
- [ ] Confirm visible changes survive form submit.

## 6. Export payload

- [ ] Use `rails_table_preference_export_payload(...)` in a controller.
- [ ] Confirm hidden columns stay out of the exported payload by default.
- [ ] Confirm exported order follows saved display order.
- [ ] Confirm grouped metadata appears when expected.

## 7. Accessibility baseline

- [ ] The editor buttons and toggles are keyboard reachable.
- [ ] Screen-reader labels remain understandable after customization.
- [ ] Drag and resize affordances still expose enough context for non-pointer users.

## 8. Scoped preset resolution

- [ ] Owner default wins when present.
- [ ] Role default wins over shared when no owner default exists.
- [ ] Organization default wins over shared when no owner/role default exists.
- [ ] Shared default is used only as the final fallback.
- [ ] Scope labels in the UI match the expected source.

## 9. Sort UI behavior

- [ ] Add `sortable: true` to a column.
- [ ] Click the header and confirm ascending sort state is shown.
- [ ] Click again and confirm descending sort state is shown.
- [ ] Click again and confirm sort is cleared.
- [ ] Confirm non-sortable columns do not change sort state.
- [ ] Confirm clicking a filter button does not toggle sort.
- [ ] Confirm dragging/resizing a header does not accidentally toggle sort.
- [ ] Confirm `aria-sort` changes appropriately.
- [ ] Confirm sortable headers do not change state while an async preset action is running.

## 10. Fixed columns and column groups

- [ ] Add `fixed: true` or `pinned: true` to a column.
- [ ] Confirm pinned cells receive pinned/fixed class and data hooks.
- [ ] Confirm the pinned column remains visible while horizontally scrolling the table container.
- [ ] If you use the generated demo example, confirm the scroll wrapper keeps `受注番号` visible while the rest of the table moves.
- [ ] Confirm multiple pinned columns do not overlap in the tested layout.
- [ ] Resize a pinned column and confirm pinned offsets are still correct.
- [ ] Reorder columns and confirm pinned offsets are recalculated.
- [ ] Hide a pinned column and confirm later pinned columns shift correctly.
- [ ] Add `group:` metadata to columns.
- [ ] Use `table_preferences_column_groups` in grouped header markup and confirm `colspan` values are correct.
- [ ] If you use the generated demo example, confirm that after changing visibility or order, saving, and reloading, the grouped header row still matches the visible leaf headers.
- [ ] Confirm leaf header cells still have `data-rails-table-preferences-column-key`.
- [ ] Confirm pinned-column resize and header drag do not start while an async preset action is running.

## 11. Export integration

- [ ] Use `rails_table_preference_export_payload` in a controller.
- [ ] Confirm hidden columns are excluded by default.
- [ ] Confirm `include_hidden: true` includes hidden columns when intended.
- [ ] Confirm exported column order follows saved display order.
- [ ] Confirm exported headers use the expected labels.
- [ ] Confirm `export_key` is used when display key and export method differ.
- [ ] Confirm group metadata is available for grouped CSV/Excel headers.
- [ ] Confirm host app authorization decides whether sensitive values are exportable.

## 12. Controller params integration

- [ ] Use `rails_table_preference_params` in a controller.
- [ ] Confirm saved text filter state becomes the expected host app param.
- [ ] Confirm saved select filter state becomes the expected host app param.
- [ ] Confirm saved date range filter state becomes the expected host app params.
- [ ] Confirm saved sort state becomes the expected sort param.
- [ ] Confirm `sort_param:` maps a display column key to the host app sort key.
- [ ] Confirm the host app search layer executes the final merged params.

## 13. Existing search form integration

- [ ] Confirm the host app's existing GET form still submits without JavaScript.
- [ ] Confirm preference-derived hidden fields do not duplicate unrelated params.
- [ ] Confirm hidden-field values update after saving a different preset.

## 14. Troubleshooting checks

- [ ] Temporarily break the preference API path and confirm the host app degrades safely.
- [ ] Confirm a missing current owner does not crash the page.
- [ ] Confirm unsupported columns are ignored rather than persisted.
