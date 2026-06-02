# Accessibility baseline

Rails Table Preferences aims to provide a practical accessibility baseline for server-rendered Rails tables.

This document explains what the gem provides and what the host application still owns.

## What the gem provides

The bundled editor and Stimulus controller provide:

- button elements for interactive controls
- labels for generated editor inputs
- configurable Japanese default labels
- localized fallback scope labels for preset options when the payload does not provide `scope_label`
- `aria-label` for drag handles, resize handles, and filter buttons
- `aria-pressed` and `aria-expanded` for filter buttons
- `aria-controls` from the open filter button to the current filter panel
- `aria-sort` for sortable table headers
- disabled states for controls that should not be used on read-only scoped presets
- a visible helper message that explains the difference between the bundled `適用`, `保存`, and `別名で保存` actions
- per-field helper copy and `aria-describedby` context for the bundled preset selector and preset name field so users can tell which saved preset will load and which name save or save as new will use
- per-button `title` and `aria-label` text on the bundled `適用`, `保存`, and `別名で保存` buttons so users can tell whether they are applying the current editor state, saving to the current preset name, or creating a separately named preset
- a visible helper message when saving from a read-only preset will create or update the owner preset path instead of overwriting the shared preset directly
- a visible helper message and `aria-describedby` context for the bundled default preset checkbox so users can tell it only takes effect when they save or save as new
- a live `role="status"` region for bundled save/load/delete feedback
- a separate visible dirty-state helper in the packaged controller when the current editor settings differ from the last loaded or saved preset settings
- a visible helper message plus explanatory `title`, `aria-label`, and `aria-describedby` text on the bundled reset button so users can tell it discards unsaved editor changes and returns to the default settings without relying only on hover text
- temporary busy-state disabling for preset controls, generated editor inputs, and bundled header buttons while bundled async preset actions are running
- keyboard-focusable buttons and inputs through native HTML elements
- per-editor ids for the preset select and preset name fields so multiple editors on one page do not collide; the bundled partial generates those ids automatically for each rendered instance, and copied/customized views should preserve the label/input pairing while keeping ids unique
- optional semantic table captions for the default `resource_table_for` and `tree_resource_table_for` partials when the host app passes `caption:`

## Sortable headers

Sortable headers receive `aria-sort`:

```html
<th data-rails-table-preferences-column-key="delivery_date" aria-sort="ascending">
  納品日
</th>
```

The controller updates the value as sort state changes:

- `none`
- `ascending`
- `descending`

## Filter buttons

Filter buttons receive an `aria-label`, `aria-pressed`, and `aria-expanded`:

```html
<button
  type="button"
  class="rails-table-preferences-filter-button"
  aria-label="絞り込み: 得意先名 (含む: ACME)"
  aria-pressed="true"
  aria-expanded="true"
  aria-controls="rails-table-preferences-filter-panel-orders_index-customer_name"
  title="絞り込み: 得意先名 (含む: ACME)">
  ▾
</button>
```

The pressed state reflects whether a filter condition is currently active for that column.

When a bundled filter is active, the button keeps its compact `▾` text but updates `title` and `aria-label` with a short operator/value summary so screen reader users and hover users can tell which condition is attached to that column without opening the panel again.

When a bundled filter panel opens, the controller moves focus into the panel, supports `Escape` to close it, and returns focus to the triggering filter button for that keyboard dismissal path. To avoid detached floating UI, the bundled panel also closes on scroll or viewport resize instead of trying to stay open at a stale position.

## Resize handles

Resize handles are generated as buttons and receive an `aria-label`:

```html
<button
  type="button"
  class="rails-table-preferences-resize-handle"
  aria-label="列幅を変更: 得意先名">
</button>
```

The bundled controller prefers the configured column label for that accessible name, falls back to the visible header text when needed, and only uses the raw column key when neither user-facing label is available.

The default behavior is pointer-oriented. Host applications that need full keyboard resizing should provide a custom controller or additional keyboard shortcuts.

## Resource table captions

When the host app uses the default `resource_table_for` or `tree_resource_table_for` partial, it can pass `caption:` to render a native `<caption>` immediately under the generated `<table>`:

```erb
<%= resource_table_for @orders, caption: "Orders" %>
<%= tree_resource_table_for @projects, caption: "Projects" %>
```

Use this for a short semantic table name that helps users distinguish the table surface. The caption is optional and only appears when the host app passes it.

Rails Table Preferences does not try to generate page-level explanations, complex table summaries, or business-specific instructions. Keep those in the host application around the generated table, or use a custom partial when the caption needs richer markup than the default surface provides.

## Drag and drop

The default column reorder behavior uses native drag and drop for editor rows and table headers. Treat those drag affordances as pointer-oriented shortcuts, not as the only supported reorder path.

The bundled editor also exposes numeric order inputs. Keyboard-only users can change a column's order number, move to the bundled `適用` action, and apply the editor state without relying on drag and drop. This is the bundled keyboard-friendly fallback for reordering.

For touch and narrow-viewport checks, do not assume table-header drag is the primary guaranteed path. Confirm the editor order inputs remain reachable and that applying those values updates the table order. Host applications that need stronger touch reordering, up/down controls, or full keyboard shortcuts should add those controls in a copied/custom controller rather than treating the bundled drag handles as a complete reorder design system.

## Read-only scoped presets

Shared, role, and organization presets may be returned as `editable: false`.

The bundled controller disables destructive/default controls for read-only presets, shows a short helper message about the save fallback, and falls back to creating or updating an owner preset when users save edits from the normal editor path.

This prevents the regular user-facing editor from accidentally overwriting shared presets while keeping the next action understandable.

## Status region and busy state

The bundled editor now includes a lightweight status region for the main async preset actions:

- loading saved settings
- saving the current settings
- saving as a new preset
- deleting the current preset
- reporting action-specific failure copy when load, save, save as new, or delete cannot complete

The default markup uses a native live region:

```html
<div
  class="rails-table-preferences-editor__status"
  role="status"
  aria-live="polite"
  aria-atomic="true">
</div>
```

While those bundled async actions are in flight, the preset select, preset name, default checkbox, action buttons, generated editor row inputs, and bundled header buttons are temporarily disabled.

The controller also ignores bundled row drag, header drag, sort, filter, and resize interactions while the async request is still in flight. This keeps the visible table state from drifting away from the payload that is currently being loaded, saved, created, or deleted.

Host applications can still replace or restyle this surface through the existing copy-based customization path when they need richer inline messaging or branded notifications.

## Dirty state helper

The packaged `rails_table_preferences/controller` entrypoint adds a small visible helper when the editor settings differ from the last loaded or saved preset settings. This helper is separate from the async `role="status"` region, so progress and success messages such as loading, saving, and deleting are not overwritten by the persistent unsaved-change cue.

The helper is shown after editor input changes, column reorder, resize, filter, or sort changes. It stays visible after `適用` when the applied settings have not been saved yet. It is cleared after a successful preset load, save, or save as new response updates the saved snapshot.

The default text is `未保存の変更があります。`. Host applications that use the package entrypoint can override the visible text per controller root with `data-rails-table-preferences-dirty-state-label-value`. Host apps using the copied base controller path should not assume this package entrypoint-only helper is available unless they copy the same behavior.

## Locale overrides for bundled copy

The current bundled helper and status copy is I18n-driven, so host applications can change wording without copying ERB or JavaScript when the existing structure is still acceptable.

Representative locale keys include:

- `rails_table_preferences.editor.action_hint`
- `rails_table_preferences.editor.read_only_preset_hint`
- `rails_table_preferences.editor.loading_status`
- `rails_table_preferences.editor.saved_status`
- `rails_table_preferences.editor.deleting_failed_status`
- `rails_table_preferences.editor.reset_hint`
- `rails_table_preferences.editor.reset_visible_hint`

Those keys feed different bundled accessibility surfaces:

- `action_hint`: the visible helper text and `aria-describedby` context for `適用`, `保存`, and `別名で保存`
- `read_only_preset_hint`: the helper text shown when a shared, role, or organization preset is read-only
- `*_status`: the live `role="status"` region used for async preset feedback
- `reset_hint`: the bundled reset button `title` and `aria-label`
- `reset_visible_hint`: the visible helper text and `aria-describedby` context for the bundled reset button

## Choosing the copy override path

Use the lightest override that matches the wording change you need.

### 1. Locale keys for bundled helper and status copy

Use locale entries when the text is already rendered in the bundled ERB partial and the existing markup is still acceptable.

Typical locale-driven surfaces include:

- preset selector and preset name helper text
- action hint copy for `適用`, `保存`, and `別名で保存`
- read-only preset helper text
- reset visible helper and button wording
- async status-region progress, success, and failure copy

This is the best default when the same wording should stay consistent across every screen that uses the bundled editor.

### 2. Stimulus values for per-root filter, sort, dirty-state, or scope wording

Use controller-root values when the copy belongs to the bundled controller surface itself or when one table needs wording that differs from another.

Representative attributes include:

- `data-rails-table-preferences-filter-label-value`
- `data-rails-table-preferences-filter-apply-label-value`
- `data-rails-table-preferences-filter-clear-label-value`
- `data-rails-table-preferences-filter-operator-label-value`
- `data-rails-table-preferences-filter-operator-labels-value`
- `data-rails-table-preferences-filter-value-label-value`
- `data-rails-table-preferences-filter-from-label-value`
- `data-rails-table-preferences-filter-to-label-value`
- `data-rails-table-preferences-sort-asc-label-value`
- `data-rails-table-preferences-sort-desc-label-value`
- `data-rails-table-preferences-sort-clear-label-value`
- `data-rails-table-preferences-dirty-state-label-value`
- `data-rails-table-preferences-scope-owner-label-value`
- `data-rails-table-preferences-scope-shared-label-value`
- `data-rails-table-preferences-scope-role-label-value`
- `data-rails-table-preferences-scope-organization-label-value`

These values affect controller-owned text such as filter button `aria-label` / `title`, bundled filter panel field labels, sort announcements, operator option labels and active-filter summaries, the package entrypoint dirty-state helper, and scope fallback labels for preset options. The bundled helper output already passes default values from I18n where those surfaces are partial-owned, but host apps can override a single controller root when a specific screen needs different wording.

The `data-rails-table-preferences-filter-operator-labels-value` attribute is a JSON object supported by the packaged `rails_table_preferences/controller` entrypoint. Keys are operator names such as `contains` or `equals`, and values are the labels shown in the bundled filter panel and active-filter summary. Host apps that use a copied base controller directly should not assume this package entrypoint-only value is available. For the controller-side contract, see [JavaScript controller notes](javascript_controller.md).

### 3. Copied ERB or copied JavaScript for markup or logic changes

Copy the bundled ERB partial when the host app needs different markup or helper-text placement, such as:

- a custom status surface instead of the bundled `role="status"` block
- extra screen-specific helper copy around preset controls
- different button layout or additional descriptive markup

Copy or replace the bundled JavaScript when the host app needs controller logic or vocabulary that is not exposed through root values, such as:

- new filter operator semantics or operator display rules beyond `filterOperatorLabels`
- different busy-state or status-update behavior
