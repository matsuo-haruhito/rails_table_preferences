# Filter panel accessibility boundary

The bundled package entrypoint keeps filter panels as lightweight popovers, not modal dialogs.

## Provided by the bundled package entrypoint

- The open filter button keeps `aria-expanded="true"` and `aria-controls` while its panel is open.
- The opened filter panel receives `role="group"`.
- The panel title receives a deterministic id derived from the panel id.
- The panel receives `aria-labelledby` pointing at that title id, so the group name follows the column label/key shown in the panel title.
- Closing the panel continues to use the base controller cleanup path, which removes stale `aria-controls` from closed filter buttons.

## Deliberately out of scope

The filter panel is still a lightweight popover. It does not add `role="dialog"`, `aria-modal`, a focus trap, or new filter query behavior.

Host applications that need a modal filter builder, richer focus management, or app-specific authorization copy should keep using the copied JavaScript/controller customization path.

## Manual QA focus

When changing filter panel markup or host-app overrides, confirm that:

- opening a filter panel moves focus into the first bundled field
- the open filter button points to the existing panel id
- the panel is named by its title text
- pressing `Escape` closes the panel and returns focus to the triggering filter button
- closing via Escape, outside click, scroll, or resize does not leave stale `aria-controls` on any filter button
