# Filter panel keyboard boundary

This note covers the bundled filter panel keyboard boundary for the default Stimulus controller.

## What the bundled controller provides

The bundled filter panel is a lightweight, body-mounted panel opened from a table header filter button. It is not a modal dialog and does not install a full focus trap.

When a filter panel opens, the controller:

- updates the triggering filter button's `aria-expanded` and `aria-controls`
- moves focus into the first bundled filter field
- closes the panel on `Escape` and returns focus to the triggering filter button
- closes the panel on outside click
- closes the panel on scroll or viewport resize so the panel does not stay detached from its header context

Tab and Shift+Tab keep using normal browser focus navigation. The bundled controller does not add sentinels, roving focus, Popover API behavior, or modal-dialog semantics around the panel.

## What host applications still own

Host applications still own final keyboard policy when a table lives inside a custom drawer, modal, sticky header shell, or dense application chrome.

Before release, check whether the host screen expects one of these policies:

- normal Tab movement can leave the panel, and the user can still understand which filter remains open
- the host app wants focus-out to close the panel
- the host app wraps the table in a modal/drawer that already owns focus containment
- the host app replaces the bundled panel with a richer widget such as autocomplete, grouped options, async loading, or a custom popover

If the host app needs a different Tab-out behavior, implement it in the copied or replacement controller for that screen. Keep the default gem controller focused on the lightweight panel contract above.

## Manual QA checklist

- Open a filter panel with the keyboard and confirm focus moves into the first bundled field.
- Press `Escape` and confirm the panel closes and focus returns to the triggering filter button.
- Reopen the panel, press Tab and Shift+Tab, and confirm the host screen's chosen Tab-out behavior is understandable.
- Confirm only the open filter button exposes `aria-expanded="true"`.
- Click outside the panel and confirm it closes.
- Scroll or resize the viewport and confirm the panel closes instead of staying detached from its header.
- Confirm the panel's Tab-out behavior does not imply a full focus trap, modal dialog, or host-app drawer policy that the bundled controller does not provide.

## Non-goals

This note does not add or require:

- a full focus trap
- Popover API or dialog migration
- sentinel elements around the panel
- remote option loading
- filter operator or query adapter changes
- a browser automation harness
