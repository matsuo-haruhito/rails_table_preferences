# Editor bulk visibility

The bundled editor exposes `全列表示` and `全列非表示` controls for the package entrypoint editor. They toggle the existing per-column `data-field="visible"` checkboxes in the editor. The table is updated only when the user runs the existing `適用`, `保存`, or `別名で保存` flow, so the settings payload shape remains unchanged.

## Scope

- Applies to every editor row that has a visible checkbox.
- Pinned and fixed columns follow the same checkbox semantics as other columns.
- Group-level visibility is not implemented in this slice.
- Host apps that copy or customize the controller or editor partial can keep their own column manager behavior.

## Manual check

- Click `全列非表示`, apply, and confirm every visible-checkbox column is hidden.
- Click `全列表示`, apply, and confirm those columns return.
- Toggle one column manually after a bulk action, then save and reload.
- Confirm async preset actions disable the bulk buttons with the rest of the editor actions.
