# Manual QA checklist

Use this checklist before asking host application users to try Rails Table Preferences in a real workflow.

The automated suite covers Ruby behavior, generator output, request behavior, helper output, adapters, and source-level JavaScript invariants. Manual QA focuses on browser behavior, host app integration, and visual/UX issues that are difficult to verify with the current test suite.

## 1. Environment and installation

- [ ] Create or select a Rails application for manual testing.
- [ ] Add the gem to the host app Gemfile.
- [ ] Run `bundle install`.
- [ ] Run the install generator.
- [ ] Confirm the generated initializer exists.
- [ ] Confirm the generated migration exists.
- [ ] Confirm the copied Stimulus controller exists.
- [ ] Confirm the copied stylesheet exists.
- [ ] Run `bin/rails db:migrate`.
- [ ] Mount `RailsTablePreferences::Engine` in `config/routes.rb`.
- [ ] Confirm the configured `mount_path` matches the route mount path.

## 2. Owner/current user configuration

- [ ] Confirm the default `current_user` method works, or configure `current_user_method`.
- [ ] Confirm the configured owner model matches the generated migration.
- [ ] Confirm preferences are saved against the expected owner record.
- [ ] Test at least two different owners and confirm preferences do not leak between owners.

## 3. Basic rendering

- [ ] Render `table_preferences_editor` on a list screen.
- [ ] Render `table_preferences_table_tag` around the target table.
- [ ] Confirm the editor is visible.
- [ ] Confirm the target table is visible.
- [ ] Confirm every target header and cell has the matching `data-rails-table-preferences-column-key`.
- [ ] Confirm Japanese column labels are shown when host app locale entries are present.
- [ ] Confirm explicit `label:` values override locale lookup.

## 4. Display preference behavior

- [ ] Hide a column from the editor and apply it.
- [ ] Show the column again and apply it.
- [ ] Reorder columns by dragging editor rows.
- [ ] Reorder columns by dragging table headers directly.
- [ ] Resize a column using the header resize handle.
- [ ] Confirm the resize hit area is easy enough to grab.
- [ ] Change a width value in the editor and apply it.
- [ ] Change a truncation value and confirm long text is truncated.
- [ ] Reset settings and confirm the table returns to default display settings.

## 5. Preset behavior

- [ ] Save the default preset.
- [ ] Reload the page and confirm the saved default preset is applied.
- [ ] Save as a new named preset.
- [ ] Select the named preset and confirm it loads.
- [ ] Update the named preset and confirm changes persist.
- [ ] Mark a preset as default.
- [ ] Reload without an explicit name and confirm the default preset loads.
- [ ] Delete a non-default preset.
- [ ] Try deleting a preset and confirm the UI remains usable afterwards.

## 6. API and network behavior

Use browser devtools while saving/loading presets.

- [ ] Confirm `GET /rails_table_preferences/preferences/:table_key` returns the preset collection.
- [ ] Confirm `POST /rails_table_preferences/preferences/:table_key` creates a preset.
- [ ] Confirm `GET /rails_table_preferences/preferences/:table_key/:name` loads a preset.
- [ ] Confirm `PATCH /rails_table_preferences/preferences/:table_key/:name` updates a preset.
- [ ] Confirm `DELETE /rails_table_preferences/preferences/:table_key/:name` deletes a preset.
- [ ] Confirm JSON requests include the Rails CSRF token.
- [ ] Confirm authenticated requests do not redirect to the login page.
- [ ] Confirm API failures show enough browser/log detail to diagnose.

## 7. Filter UI behavior

- [ ] Add a text filter column and confirm the filter button appears.
- [ ] Open the filter panel.
- [ ] Apply a `contains` condition.
- [ ] Apply an `equals` condition.
- [ ] Apply a blank/present condition.
- [ ] Clear the filter.
- [ ] Add a select filter column and choose one or more values.
- [ ] Add a date filter column and set from/to values.
- [ ] Add a number filter column and set from/to values.
- [ ] Confirm filter panel layering is not clipped by the surrounding layout.
- [ ] Confirm opening one filter panel closes or does not visually conflict with another.

## 8. Sort UI behavior

- [ ] Add `sortable: true` to a column.
- [ ] Click the header and confirm ascending sort state is shown.
- [ ] Click again and confirm descending sort state is shown.
- [ ] Click again and confirm sort is cleared.
- [ ] Confirm non-sortable columns do not change sort state.
- [ ] Confirm clicking a filter button does not toggle sort.
- [ ] Confirm dragging/resizing a header does not accidentally toggle sort.
- [ ] Confirm `aria-sort` changes appropriately.

## 9. Controller params integration

- [ ] Use `rails_table_preference_params` in a controller.
- [ ] Confirm saved text filter state becomes the expected host app param.
- [ ] Confirm saved select filter state becomes the expected host app param.
- [ ] Confirm saved date range filter state becomes the expected host app params.
- [ ] Confirm saved sort state becomes the expected sort param.
- [ ] Confirm `sort_param:` maps a display column key to the host app sort key.
- [ ] Confirm the host app search layer executes the final merged params.

## 10. Existing search form integration

- [ ] Add `table_preferences_hidden_fields` to an existing search form.
- [ ] Confirm hidden fields are generated for saved filters.
- [ ] Confirm array params render with `[]` names where expected.
- [ ] Confirm blank filter values are not submitted unnecessarily.
- [ ] Confirm normal user-entered search params still work.
- [ ] Confirm saved preference params and user-entered params merge in the intended precedence order.

## 11. Ransack integration

- [ ] Use `adapter: :ransack` in a controller.
- [ ] Confirm text filters become expected Ransack predicates.
- [ ] Confirm date/number filters become expected Ransack predicates.
- [ ] Confirm sorts become `s` params.
- [ ] Use `table_preferences_hidden_fields` with `namespace: :q`.
- [ ] Confirm generated hidden fields use `q[...]` names.

## 12. Ignored columns and sensitive fields

- [ ] Mark a column with `ignored: true` and confirm it does not appear in the editor.
- [ ] Pass `ignored_columns:` and confirm matching columns do not appear in the editor.
- [ ] Confirm old saved settings cannot reintroduce ignored columns into the editor payload.
- [ ] Confirm the host application does not render sensitive ignored columns in HTML.
- [ ] Confirm authorization/query selection still protects sensitive values server-side.

## 13. Customization

- [ ] Run `bin/rails generate rails_table_preferences:views`.
- [ ] Edit the copied ERB partial and confirm the app uses it.
- [ ] Run `bin/rails generate rails_table_preferences:stylesheets`.
- [ ] Edit the copied CSS and confirm visual changes apply.
- [ ] Run `bin/rails generate rails_table_preferences:javascript`.
- [ ] Edit the copied Stimulus controller and confirm behavior changes apply.
- [ ] Confirm host app can skip JavaScript copying when providing its own controller.
- [ ] Confirm host app can skip stylesheet copying when providing its own CSS.

## 14. Browser and layout checks

- [ ] Check the screen in Chrome or Edge.
- [ ] Check the screen at a narrow desktop width.
- [ ] Check the screen with long Japanese labels.
- [ ] Check the screen with long table values.
- [ ] Confirm editor inputs do not overlap.
- [ ] Confirm filter panels are not clipped.
- [ ] Confirm column width controls remain usable.
- [ ] Confirm table operation hit areas do not interfere with normal table links/buttons.

## 15. Regression checklist from early implementation issues

- [ ] Column width changes apply to the table, not to editor cards.
- [ ] Editor row card widths do not unexpectedly mirror table column widths.
- [ ] Filter panel appears above surrounding content and is not clipped.
- [ ] The settings dialog/editor remains visible after CSS changes.
- [ ] Table drag, resize, filter, and sort interactions do not block each other.
- [ ] Saved filter/sort state survives editor apply operations.
- [ ] Current column metadata overrides stale saved metadata for labels, filters, and sortable state.

## Sign-off

Record the result before asking real users to try the feature:

```text
Rails app:
Rails version:
Ruby version:
Browser:
Owner model:
Mount path:
QA date:
QA result:
Known issues:
```
