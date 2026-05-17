# Accessibility baseline

Rails Table Preferences aims to provide a practical accessibility baseline for server-rendered Rails tables.

This document explains what the gem provides and what the host application still owns.

## What the gem provides

The bundled editor and Stimulus controller provide:

- button elements for interactive controls
- labels for generated editor inputs
- configurable Japanese default labels
- `aria-label` for drag handles, resize handles, and filter buttons
- `aria-pressed` for active filter buttons
- `aria-sort` for sortable table headers
- disabled states for controls that should not be used on read-only scoped presets
- keyboard-focusable buttons and inputs through native HTML elements

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

Filter buttons receive an `aria-label` and `aria-pressed`:

```html
<button
  type="button"
  class="rails-table-preferences-filter-button"
  aria-label="絞り込み: 得意先名"
  aria-pressed="true">
  ▾
</button>
```

The pressed state reflects whether a filter condition is currently active for that column.

## Resize handles

Resize handles are generated as buttons and receive an `aria-label`:

```html
<button
  type="button"
  class="rails-table-preferences-resize-handle"
  aria-label="列幅を変更: customer_name">
</button>
```

The default behavior is pointer-oriented. Host applications that need full keyboard resizing should provide a custom controller or additional keyboard shortcuts.

## Drag and drop

The default column reorder behavior uses native drag and drop. The editor still exposes numeric order inputs, so users are not forced to rely only on drag and drop.

For applications with stricter accessibility requirements, prefer documenting the numeric order inputs as the keyboard-friendly reorder path or replacing the drag behavior in a custom controller.

## Read-only scoped presets

Shared, role, and organization presets may be returned as `editable: false`.

The bundled controller disables destructive/default controls for read-only presets and falls back to creating an owner preset when users save edits from the normal editor path.

This prevents the regular user-facing editor from accidentally overwriting shared presets.

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
- The preset select, preset name, default checkbox, and action buttons are labeled.
- Sortable headers expose the current sort state.
- Active filters expose an active pressed state.
- Read-only scoped presets disable destructive actions.
- The table remains understandable when columns are hidden.
- Sticky/fixed columns do not cover focused content.
- Custom colors still meet the host application's contrast requirements.

## Customization path

If the default behavior is not sufficient, use the existing copy-based customization path:

```bash
bin/rails generate rails_table_preferences:views
bin/rails generate rails_table_preferences:javascript
bin/rails generate rails_table_preferences:stylesheets
```

Then adjust the generated ERB, Stimulus controller, or CSS in the host application.
