# Helper-free table root manual QA

Use this focused checklist when a host app keeps its own `<table>` partial or another renderer owns the table markup, while Rails Table Preferences is mounted manually on the table root or on a wrapper around the first nested table.

Start here after the [Manual QA checklist](manual_qa.md) points you to helper-free, custom partial, or host-app-owned table markup. This checklist keeps the browser evidence narrow: table-root and wrapper-root wiring, managed versus unmanaged columns, and persistence for the supported DOM contract.

This is a narrow smoke checklist for the supported DOM contract described in [JavaScript controller notes](javascript_controller.md#minimal-dom-contract-for-helper-free-tables). It does not replace the full [Manual QA checklist](manual_qa.md) before broader host-app rollout.

## Setup

- [ ] Render a host-app-owned table partial without `table_preferences_table_tag` or `resource_table_for`.
- [ ] Mount `data-controller="rails-table-preferences"` directly on the `<table>` for one pass.
- [ ] Repeat with the controller root on a wrapper element that contains the target `<table>` as the first nested table.
- [ ] Provide the same core controller values used by normal helper output: table key, preset collection URL, preset URL, columns JSON, and settings JSON.
- [ ] Keep at least one host-app-owned column without `data-rails-table-preferences-column-key`, such as actions, notes, or links.

## Display behavior

- [ ] Hide one managed column and apply the change.
- [ ] Confirm matching managed header and body cells inside the target table are hidden.
- [ ] Confirm unmanaged columns remain visible and usable.
- [ ] Change one managed column width and apply the change.
- [ ] Confirm only cells with the matching managed column key inside the target table receive the width change.
- [ ] Confirm columns outside the target table or unmanaged columns are not affected by the display change.

## Sort, filter, and table boundary

- [ ] Click a sortable managed header and confirm the sort state updates only for that target table.
- [ ] Open a filter panel on a managed header and confirm it is attached to the expected header context.
- [ ] Confirm filter and sort interactions do not trigger host-app buttons or links in unmanaged action columns.
- [ ] If the wrapper contains another table before the intended target table, move or adjust the markup so the intended table is the first nested table before treating the setup as supported.

## Persistence smoke

- [ ] Save the helper-free table preset.
- [ ] Reload the page and confirm managed visibility/order/width state returns.
- [ ] Confirm unmanaged columns and host-app-owned cell content still render from the host partial after reload.

## Sign-off note

Record whether the tested shape was table-root, wrapper-root, or both. If only one shape was checked, note why the other shape was skipped and whether source-level coverage or a later browser pass should cover it.
