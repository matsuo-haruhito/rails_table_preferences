# render_editor:false placement manual QA

Use this focused checklist when a host application renders the bundled editor away from the default resource table position by passing `render_editor: false` to `resource_table_for` or `tree_resource_table_for`.

This checklist is intentionally about placement and review evidence. It does not add a drawer, toolbar, tab component, new helper option, or custom partial contract.

## Scope

Use this checklist for screens where the editor appears in a toolbar, drawer, tab panel, sidebar, or separate partial while the table still uses the bundled resource table partial.

Do not use this checklist as proof for a custom table partial redesign. If the table markup changes, combine this with the custom partial checks in `manual_qa.md`.

## Setup

- [ ] Render the editor explicitly with the same `table_key`, `settings`, and `columns` used by the resource table.
- [ ] Render `resource_table_for` or `tree_resource_table_for` with `render_editor: false`.
- [ ] Confirm the table still receives the Rails Table Preferences data attributes and managed column keys.
- [ ] Confirm the editor and table are updated together after Turbo navigation, Turbo Frame replacement, drawer open, or tab switch when the host app uses those patterns.

## Placement states

Check at least one representative placement used by the host app.

- [ ] Toolbar placement: confirm the editor controls are close enough to the table context and do not hide the table caption, filters, or action buttons.
- [ ] Drawer placement: open and close the drawer, then confirm the editor still targets the same table and the status region remains visible or reachable.
- [ ] Tab placement: switch away and back, then confirm editor values, focus, and table settings remain synchronized.
- [ ] Separate partial placement: confirm the editor and table are not rendered from mismatched settings or stale column metadata.

## Interaction smoke

- [ ] Hide one column, apply the editor change, and confirm the target table updates.
- [ ] Change one order input, apply the editor change, and confirm the target table order updates.
- [ ] Save a preset, reload or revisit the screen, and confirm the placed editor and table both show the saved state.
- [ ] Load another preset and confirm the placed editor, status copy, and table state all update together.
- [ ] Trigger one failed preset action if the screen has a practical failure path, then confirm controls recover and the status message is still visible from the placement.

## Layout and accessibility smoke

- [ ] At a narrow desktop width, confirm the placed editor does not overlap the table, page toolbar, drawer controls, tab labels, or sticky content.
- [ ] In a short viewport, confirm helper copy, read-only hints, and status messages remain reachable without hiding the Apply or Save actions.
- [ ] Open a filter panel from a right-edge or horizontally scrolled column and confirm the placement does not make Apply or Clear unreachable.
- [ ] Move keyboard focus from the placed editor to the table and back, then confirm focus indicators are visible and the route is understandable.
- [ ] Confirm any drawer or tab label is host-app-owned copy and does not imply Rails Table Preferences owns the surrounding navigation pattern.

## Evidence to record

Record the following in the PR body or review comment:

- placement checked: toolbar, drawer, tab, sidebar, or separate partial
- table key and representative screen name
- viewport checked, including one narrow or short viewport when relevant
- whether editor and table were replaced together by Turbo or rendered from separate partials
- apply/save/load action checked
- filter panel reachability checked or intentionally skipped with a reason
- remaining host-app responsibility, such as drawer focus trap, tab semantics, or custom partial layout
