# Filter panel popup semantics

The bundled filter panel is a lightweight, non-modal floating region. It is not a menu, modal dialog, Popover API surface, or focus-trapped component.

This boundary keeps the default controller small while still giving host applications a predictable accessibility baseline.

## Bundled behavior

When a filterable header is rendered, the bundled controller creates a native button next to the column label.

The button owns:

- `aria-label`, using the column label and active filter summary
- `aria-pressed`, when the column currently has an active filter condition
- `aria-expanded`, while the floating panel is open
- `aria-controls`, only while the floating panel is open

When the panel opens, the controller creates one body-mounted `.rails-table-preferences-filter-panel` element and gives it a stable id derived from the table key and column key. The triggering button points at that id through `aria-controls` until the panel closes.

## Non-modal boundary

The panel intentionally does not set `role="dialog"`, `aria-modal`, or a focus trap. It also does not expose `aria-haspopup` as a menu/dialog promise.

The bundled interaction instead stays limited to:

- moving focus into the first bundled filter field on open
- closing on `Escape`
- returning focus to the triggering button for the `Escape` close path
- closing on outside click
- closing on scroll or viewport resize so the body-mounted panel does not drift away from the header cell

This means normal browser Tab / Shift+Tab behavior can leave the panel. Host applications that need modal focus containment, custom popover semantics, or menu-like keyboard behavior should copy or replace the controller and verify that richer interaction in their own layout.

## Review checks

For PRs that touch the bundled filter panel, record whether the change affects semantics, positioning, or keyboard behavior.

Use a representative filterable column and confirm:

- the filter button keeps a useful `aria-label`
- `aria-expanded` changes only while the panel is open
- `aria-controls` points to the current panel id only while the panel is open
- `Escape` closes the panel and returns focus to the button
- outside click, scroll, and viewport resize close the panel
- Apply and Clear remain reachable in a short viewport

When a PR only changes docs or source guards, source review is enough. When a PR changes runtime DOM, CSS, positioning, or focus behavior, record browser-capable evidence or leave a clear handoff for that rendered check.

## Non-goals

- Modal dialog semantics
- Full focus trap
- Popover API migration
- Menu role or menuitem keyboard model
- Remote option loading or async select widgets
- Query execution or adapter changes
