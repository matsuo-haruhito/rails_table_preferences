# Editor root HTML options

`table_preferences_editor(...)` accepts `html_options:` for host-app attributes that belong on the bundled editor root element.

Use it when the default partial is still correct, but the page needs a stable root `id`, an extra styling class, a generic `data-*` hook, or an `aria-*` attribute for placement inside a drawer, toolbar, modal, or analytics wrapper.

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: @table_columns,
  title: "受注一覧の表示設定",
  html_options: {
    id: "orders-table-settings",
    class: "drawer-panel",
    data: { turbo_frame: "orders_preferences", analytics_area: "orders" },
    aria: { label: "Orders table settings" }
  }
) %>
```

The helper keeps the bundled `rails-table-preferences-editor` class and merges any host class you pass. Generic `data-*` values are rendered on the root element.

Rails Table Preferences-owned Stimulus wiring stays authoritative:

- `data-controller` remains `rails-table-preferences`.
- `data-rails-table-preferences-*` values such as table key, URLs, settings JSON, columns JSON, and status labels still come from the helper and bundled partial.
- Passing those keys through `html_options:` will not replace the gem-owned values.

## Root id and internal ids

Use `html_options[:id]` when the host page needs a stable root selector for a drawer, tab panel, analytics hook, system test, or browser evidence. That id belongs to the outer editor element only.

The bundled partial also generates internal ids for the title, preset selector, preset name field, helper text, read-only hints, and status region. Those ids use the editor instance prefix so `aria-labelledby` and `aria-describedby` references stay unique when more than one editor is rendered in the same DOM.

When a screen renders multiple editors for the same table key, pass a distinct `editor_instance_key` for each editor that needs stable internal ids:

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: @table_columns,
  editor_instance_key: "orders-drawer",
  html_options: { id: "orders-table-settings-drawer" }
) %>

<%= table_preferences_editor(
  table_key: :orders,
  columns: @table_columns,
  editor_instance_key: "orders-toolbar",
  html_options: { id: "orders-table-settings-toolbar" }
) %>
```

Use the root id for host-owned placement, styling, and test targeting. Use `editor_instance_key` only when the generated internal ids must be stable across renders or when multiple editor instances are present at once. If `editor_instance_key` is omitted, the bundled partial generates a short unique prefix so duplicate internal ids are avoided by default.

`html_options:` is only for root attributes. It does not change the editor layout, preset controls, action buttons, generated internal ids, persistence behavior, authorization, or the bundled Stimulus controller contract. For structural changes inside the editor, copy the ERB partial instead and keep the data attributes documented in [Bundled editor i18n keys](editor_i18n.md) aligned with the controller.
