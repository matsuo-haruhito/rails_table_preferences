# Manual QA checklist

Use this checklist before asking host application users to try Rails Table Preferences in a real workflow.

The automated suite covers Ruby behavior, generator output, request behavior, helper output, adapters, and source-level JavaScript invariants. Manual QA focuses on browser behavior, host app integration, accessibility, and visual/UX issues that are difficult to verify with the current test suite.

## Quick smoke before the full checklist

Use this short path when you need a first browser confidence check for a docs PR, release candidate, generated demo update, or early host-app adoption pass. It is not a replacement for the full checklist below. Run the full checklist before broader host-app rollout, before changing custom integration points, or when a quick smoke reveals anything suspicious.

- [ ] Open the generated demo or a representative host-app list screen and confirm the editor and table both render.
- [ ] Hide one non-sensitive column, apply the change, and confirm the table updates without hiding required actions or links.
- [ ] Save the preset, reload the page, and confirm the saved visibility/order state returns.
- [ ] Apply one representative text/select/date/number filter and confirm the host app or demo rows narrow as expected.
- [ ] Click one sortable header and confirm the visible row order or outgoing host-app sort params change as expected.
- [ ] Switch to another owner or demo owner link and confirm saved presets do not leak between owners.
- [ ] Open one filter panel or preset action with keyboard focus and confirm focus, labels, and status copy remain understandable.
- [ ] Check one narrow desktop width and one long-label or long-value row to confirm editor controls, filter panels, and fixed columns do not overlap or become unreachable.

After this quick smoke, continue into the relevant sections below for the feature area you changed. For release sign-off or host-app launch, complete the full checklist and record any skipped areas in the sign-off notes.

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
- [ ] If you use the generated demo example, confirm `Host app owner`, `Demo owner A`, and `Demo owner B` switch the owner context without changing authentication code.
- [ ] If you use the generated demo example, confirm the `Current owner` summary follows the active owner link before saving or loading presets.

## 3. Basic rendering

- [ ] Render `table_preferences_editor` on a list screen.
- [ ] Render `table_preferences_table_tag` around the target table.
- [ ] Confirm the editor is visible.
- [ ] Confirm the target table is visible.
- [ ] Confirm every target header and cell has the matching `data-rails-table-preferences-column-key`.
- [ ] Confirm Japanese column labels are shown when host app locale entries are present.
- [ ] Confirm explicit `label:` values override locale lookup.
- [ ] Render two editors on one page and confirm each preset label focuses the matching select/input.

## 4. Display preference behavior

- [ ] Hide a column from the editor and apply it.
- [ ] Show the column again and apply it.
- [ ] Reorder columns by dragging editor rows.
- [ ] Reorder columns by dragging table headers directly.
- [ ] Resize a column using the header resize handle.
- [ ] Hover the header resize handle and confirm a lightweight visual cue appears without covering the header label, filter button, or sort indicator.
- [ ] Focus the header resize handle with the keyboard and confirm the focus cue is visible.
- [ ] Double-click a header resize handle and confirm the column auto-fits to its visible content.
- [ ] Confirm the resize hit area is easy enough to grab.
- [ ] Change a width value in the editor and apply it.
- [ ] Change a truncation value and confirm long text is truncated.
- [ ] Add representative `wrap`, `nowrap`, and `ellipsis` columns and confirm each overflow mode stays visually distinct.
- [ ] Reset settings and confirm the table returns to default display settings.
- [ ] Confirm the visible reset helper explains that unsaved editor changes are discarded and defaults are restored without relying on hover text.
- [ ] Hover or focus the reset button and confirm the button hint matches the visible reset helper.

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
- [ ] Confirm the bundled action hint explains the difference between apply, save, and save as new.
- [ ] Confirm the preset selector helper copy explains that it chooses which saved settings to load or switch to.
- [ ] Confirm the preset name helper copy explains that save and save as new use that field as the edited preset name.
- [ ] Confirm save/load/delete actions update the bundled status region with understandable progress and result copy.
- [ ] Confirm async preset actions temporarily disable the preset select, preset name, default checkbox, action buttons, and generated editor row inputs.
- [ ] Confirm drag-reordering editor rows does not start while an async preset action is running.
- [ ] Confirm those controls re-enable after success.
- [ ] Trigger at least one API failure and confirm the matching action-specific failure status appears and the controls recover.
- [ ] Prefer a lightweight browser-devtools failure such as request blocking, then unblock it and confirm the same action succeeds normally.

## 6. Scoped preset behavior

- [ ] Create or seed a shared preset and confirm it appears in the preset selector.
- [ ] Create or seed a role preset and confirm it appears only for matching role context.
- [ ] If you use the generated demo example, configure `scope_context_method = :table_preference_scope_context` once, use `Role preset lane`, and confirm `担当ビュー [role:operations]` appears.
- [ ] Create or seed an organization preset and confirm it appears only for matching organization context.
- [ ] If you use the generated demo example, configure `scope_context_method = :table_preference_scope_context` once, use `Organization preset lane`, and confirm `東京組織ビュー [organization:tokyo-hq]` appears.
- [ ] If you use the generated demo example, use `Host app context`, `Owner-only baseline`, `Role preset lane`, and `Organization preset lane` to switch the scope context without editing `ApplicationController` between requests.
- [ ] If you use the generated demo example, confirm the `Current scope context` summary follows the active scope link before reading the preset selector.
- [ ] Confirm preset options show enough scope context to distinguish owner/shared/role/organization presets.
- [ ] Confirm owner default is preferred over role, organization, and shared defaults.
- [ ] Confirm role default is preferred over organization and shared defaults when there is no owner default.
- [ ] In the generated demo flow, use `Owner-only baseline` to clear representative role/organization context and compare the shared baseline again.
- [ ] In the generated demo flow, clear any owner default and confirm `担当ビュー [role:operations]` wins before `共有ビュー [shared]`.
- [ ] In the generated demo flow, use `Organization preset lane` without a matching role default and confirm `東京組織ビュー [organization:tokyo-hq]` wins before `共有ビュー [shared]`.
- [ ] Confirm shared presets are selectable by normal users.
- [ ] Confirm shared/role/organization presets are not deleted from the normal user-facing editor.
- [ ] Confirm the read-only hint explains that saving changes from a read-only scoped preset creates or updates an owner preset, rather than overwriting the shared preset.
- [ ] Confirm host app authorization protects any admin UI for shared/role/organization preset management.

## 7. API and network behavior

Use browser devtools while saving/loading presets.

For a quick failure-path check, temporarily block one preference API URL in browser devtools, confirm the failed request surfaces the matching action-specific failure state, then remove the block and retry once.

- [ ] Confirm `GET /rails_table_preferences/preferences/:table_key` returns the preset collection.
- [ ] Confirm `POST /rails_table_preferences/preferences/:table_key` creates a preset.
- [ ] Confirm `GET /rails_table_preferences/preferences/:table_key/:name` loads a preset.
- [ ] Confirm `PATCH /rails_table_preferences/preferences/:table_key/:name` updates a preset.
- [ ] Confirm `DELETE /rails_table_preferences/preferences/:table_key/:name` deletes a preset.
- [ ] Confirm JSON requests include the Rails CSRF token.
- [ ] Confirm authenticated requests do not redirect to the login page.
- [ ] Confirm API failures show enough browser/log detail to diagnose.

## 8. Filter UI behavior

- [ ] Add a text filter column and confirm the filter button appears.
- [ ] Open the filter panel.
- [ ] Confirm only the open filter button exposes `aria-expanded="true"`.
- [ ] Confirm focus moves into the filter panel when it opens.
- [ ] Press `Escape` and confirm the panel closes and focus returns to the triggering filter button.
- [ ] Re-open the panel and apply a `contains` condition.
- [ ] Confirm switching the operator while the panel stays open updates the visible input controls immediately.
- [ ] Confirm choosing `between` replaces the single value input with `from` / `to` inputs.
- [ ] Confirm choosing `blank` / `present` or boolean operators removes unnecessary value inputs.
- [ ] Confirm the active filter button exposes a short operator/value summary through hover title or accessible name.
- [ ] Apply an `equals` condition.
- [ ] Apply a blank/present condition.
- [ ] Clear the filter.
- [ ] Add a select filter column and choose one or more values.
- [ ] In a short viewport, open a filter panel that includes a multi-select or several fields and confirm the panel scrolls enough to reach Apply and Clear.
- [ ] Add a date filter column and set from/to values.
- [ ] Add a number filter column and set from/to values.
- [ ] Confirm multiple active filters still leave header controls usable while exposing summary context per column.
- [ ] Confirm filter panel layering is not clipped by the surrounding layout.
- [ ] Confirm opening one filter panel closes or does not visually conflict with another.
- [ ] Confirm page scroll, container scroll, or viewport resize closes the panel instead of leaving it detached from the header context.
- [ ] Confirm filter buttons do not reopen or change state while an async preset action is running.

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
- [ ] While horizontally scrolled, confirm focused links, buttons, inputs, and filter buttons remain visible and clickable near pinned cells.
- [ ] Confirm focus outlines are not clipped by the scroll wrapper and are not hidden behind pinned header or body cells.
- [ ] Confirm pinned cells use an opaque background and app-specific `z-index` order so scrolled content, filter panels, dropdowns, and surrounding app chrome do not visually conflict.
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

- [ ] Add `table_preferences_hidden_fields` to an existing search form.
- [ ] Confirm hidden fields are generated for saved filters.
- [ ] Confirm array params render with `[]` names where expected.
- [ ] Confirm blank filter values are not submitted unnecessarily.
- [ ] Confirm normal user-entered search params still work.
- [ ] Confirm saved preference params and user-entered params merge in the intended precedence order.

## 14. Ransack integration

- [ ] Use `adapter: :ransack` in a controller.
- [ ] Confirm text filters become expected Ransack predicates.
- [ ] Confirm date/number filters become expected Ransack predicates.
- [ ] Confirm sorts become `s` params.
- [ ] Use `table_preferences_hidden_fields` with `namespace: :q`.
- [ ] Confirm generated hidden fields use `q[...]` names.

## 15. Ignored columns and sensitive fields

- [ ] Mark a column with `ignored: true` and confirm it does not appear in the editor.
- [ ] Pass `ignored_columns:` and confirm matching columns do not appear in the editor.
- [ ] Confirm old saved settings cannot reintroduce ignored columns into the editor payload.
- [ ] Confirm the host application does not render sensitive ignored columns in HTML.
- [ ] Confirm authorization/query selection still protects sensitive values server-side.

## 16. Accessibility baseline

- [ ] Confirm all editor controls can receive keyboard focus.
- [ ] Confirm focus order is understandable.
- [ ] Confirm preset select, preset name, default checkbox, and action buttons have labels.
- [ ] Confirm the action row helper text or accessible names explain the difference between apply, save, and save as new.
- [ ] Confirm the preset selector helper copy or accessible description explains that it loads or switches the saved preset.
- [ ] Confirm the preset name helper copy or accessible description explains that save and save as new use that field as the edited preset name.
- [ ] Confirm the reset visible helper, hover text, or accessible name explains that current edits are discarded and defaults are restored.
- [ ] Confirm the bundled `role="status"` region announces preset action progress and result copy.
- [ ] Confirm filter buttons expose a useful accessible label.
- [ ] Confirm active filter buttons update `aria-pressed`.
- [ ] Confirm active filter buttons expose a short operator/value summary in `title` or `aria-label`.
- [ ] Confirm the open filter button updates `aria-expanded` and `aria-controls`.
- [ ] Confirm bundled filter panel focus returns to the triggering button when closed with `Escape`.
- [ ] Confirm sortable headers update `aria-sort`.
- [ ] Confirm resize handles expose the visible column name, not only an internal column key.
- [ ] Confirm focused resize handles have a visible cue while preserving the existing drag and double-click behavior.
- [ ] Confirm numeric order inputs provide a keyboard-friendly alternative to drag and drop.
- [ ] Confirm read-only scoped presets disable destructive/default controls.
- [ ] Confirm read-only scoped presets explain that saves fall back to the owner preset path without implying they only create a brand-new preset.
- [ ] Confirm async preset actions temporarily disable preset controls and re-enable them after success or failure.
- [ ] Confirm async preset actions also keep editor row inputs, drag handles, filter buttons, resize handles, and sortable headers from changing state until the request finishes.
- [ ] Confirm sticky/fixed columns do not cover focused links, buttons, or inputs while the table is horizontally scrolled.
- [ ] Confirm custom host app scroll containers, backgrounds, and `z-index` overrides keep focus outlines and interactive cell content visible.
- [ ] Confirm custom host app colors meet the application's contrast requirements.

## 17. Customization

- [ ] Run `bin/rails generate rails_table_preferences:views`.
- [ ] Edit the copied ERB partial and confirm the app uses it.
- [ ] Run `bin/rails generate rails_table_preferences:stylesheets`.
- [ ] Edit the copied CSS and confirm visual changes apply.
- [ ] Run `bin/rails generate rails_table_preferences:javascript`.
- [ ] Edit the copied Stimulus controller and confirm behavior changes apply.
- [ ] Confirm host app can skip JavaScript copying when providing its own controller.
- [ ] Confirm host app can skip stylesheet copying when providing its own CSS.

## 18. Browser and layout checks

- [ ] Check the screen in Chrome or Edge.
- [ ] Check the screen at a narrow desktop width.
- [ ] Check the screen with long Japanese labels.
- [ ] Check the screen with long table values.
- [ ] Confirm editor inputs do not overlap.
- [ ] Confirm filter panels are not clipped.
- [ ] Confirm short viewport filter panels keep Apply and Clear reachable through panel scrolling.
- [ ] Confirm column width controls remain usable.
- [ ] Confirm table operation hit areas do not interfere with normal table links/buttons.

## 19. Regression checklist from early implementation issues

- [ ] Column width changes apply to the table, not to editor cards.
- [ ] Editor row card widths do not unexpectedly mirror table column widths.
- [ ] Filter panel appears above surrounding content and is not clipped.
- [ ] The settings dialog/editor remains visible after CSS changes.
- [ ] Table drag, resize, filter, and sort interactions do not block each other.
- [ ] Saved filter/sort state survives editor apply operations.
- [ ] Current column metadata overrides stale saved metadata for labels, filters, sortable state, and pinned state.

## Sign-off