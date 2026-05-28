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
- per-button `title` and `aria-label` text on the bundled `適用`, `保存`, and `別名で保存` buttons so users can tell whether they are applying the current editor state, saving to the current preset name, or creating a separately named preset
- a visible helper message when saving from a read-only preset will create or update the owner preset path instead of overwriting the shared preset directly
- a visible helper message and `aria-describedby` context for the bundled default preset checkbox so users can tell it only takes effect when they save or save as new
- a live `role="status"` region for bundled save/load/delete feedback
- explanatory `title` and `aria-label` text on the bundled reset button so users can tell it discards unsaved editor changes and returns to the default settings
- temporary busy-state disabling for preset controls, generated editor inputs, and bundled header buttons while bundled async preset actions are running
- keyboard-focusable buttons and inputs through native HTML elements
- per-editor ids for the preset select and preset name fields so multiple editors on one page do not collide; the bundled partial generates those ids automatically for each rendered instance, and copied/customized views should preserve the label/input pairing while keeping ids unique

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

## Drag and drop

The default column reorder behavior uses native drag and drop. The editor still exposes numeric order inputs, so users are not forced to rely only on drag and drop.

For applications with stricter accessibility requirements, prefer documenting the numeric order inputs as the keyboard-friendly reorder path or replacing the drag behavior in a custom controller.

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

## Locale overrides for bundled copy

The current bundled helper and status copy is I18n-driven, so host applications can change wording without copying ERB or JavaScript when the existing structure is still acceptable.

Representative locale keys include:

- `rails_table_preferences.editor.action_hint`
- `rails_table_preferences.editor.read_only_preset_hint`
- `rails_table_preferences.editor.loading_status`
- `rails_table_preferences.editor.saved_status`
- `rails_table_preferences.editor.deleting_failed_status`
- `rails_table_preferences.editor.reset_hint`

Those keys feed different bundled accessibility surfaces:

- `action_hint`: the visible helper text and `aria-describedby` context for `適用`, `保存`, and `別名で保存`
- `read_only_preset_hint`: the helper text shown when a shared, role, or organization preset is read-only
- `*_status`: the live `role="status"` region used for async preset feedback
- `reset_hint`: the bundled reset button `title` and `aria-label`

Minimal host-app override example:

```yaml
ja:
  rails_table_preferences:
    editor:
      action_hint: 適用は現在の表示だけを更新し、保存は現在の設定名へ反映、別名で保存は新しい設定として残します。
      read_only_preset_hint: この設定は直接更新できません。保存すると個人用設定として保存されます。
      loading_status: 設定を読み込み中です...
      saved_status: 設定を保存しました。
      deleting_failed_status: 設定の削除を完了できませんでした。
      reset_hint: 保存前の変更を破棄して初期表示へ戻します。
```

If the host app also needs per-screen wording, different markup, or a custom status surface, keep using the existing copy-based path by copying the bundled ERB partial or controller.

## Host application responsibilities

The host application owns:

- semantic table markup
- table captions when needed
- page-level headings and instructions
- focus order around surrounding UI
- color contrast after applying app-specific styles
- keyboard behavior beyond native form controls
- custom confirmation dialogs
- authorization messaging
- testing with the application's real design system

## Manual checks

Before releasing a screen, check:

- All editor controls can receive focus.
- Focus order is understandable.
- The preset select, preset name, default checkbox, action buttons, and status region are labeled.
- The bundled action hint or accessible names explain the difference between apply, save, and save as new.
- The default checkbox helper text or accessible description explains that it only takes effect when the user saves or saves as new.
- The reset button hover text or accessible name explains that it discards unsaved editor changes and returns to the default settings.
- Sortable headers expose the current sort state.
- Active filters expose an active pressed state.
- Active filter buttons expose a short summary through `title` or `aria-label`.
- Filter buttons expose expanded state only while their panel is open.
- Opening a filter panel moves focus into the first bundled field.
- `Escape` closes the bundled filter panel and returns focus to the triggering filter button.
- Scroll or viewport resize does not leave the bundled filter panel detached from its header context.
- Read-only scoped presets disable destructive/default controls.
- Read-only scoped presets show helper text that explains the save fallback goes to the owner preset path without implying it always creates a brand-new preset.
- Save/load/delete actions update the status region with understandable progress, result, and action-specific failure copy.
- Async preset actions temporarily disable controls and re-enable them after completion.
- Async preset actions keep editor row inputs, drag handles, filter buttons, resize handles, and sortable headers from changing state until the request completes.
- Resize handles announce the user-facing column label rather than only an internal column key.
- The table remains understandable when columns are hidden.
- Sticky/fixed columns do not cover focused content.
- Custom colors still meet the host application's contrast requirements.
- If the host app overrides bundled helper or status copy, the locale entries still match the intended action and accessibility context.

## Customization path

If the default behavior is not sufficient, use the existing copy-based customization path:

```bash
bin/rails generate rails_table_preferences:views
bin/rails generate rails_table_preferences:javascript
bin/rails generate rails_table_preferences:stylesheets
```

Then adjust the generated ERB, Stimulus controller, or CSS in the host application.