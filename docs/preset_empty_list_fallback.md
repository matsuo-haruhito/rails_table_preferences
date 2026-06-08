# Empty Preset List Fallback

The bundled editor keeps the preset selector populated even when the mounted preferences collection returns `preferences: []`.

In that normal empty-list case, the controller renders the current preset name as the only option instead of showing an empty selector. This keeps Apply, Save, Save as new, and Delete context tied to the settings that are currently applied in the editor and table.

## What This Means

- `preferences: []` is a valid first-run or owner-without-saved-presets state.
- The selector option represents the current applied preset name, not a persisted preset that was found on the server.
- The option remains editable so the user can save or save-as-new from the current settings without switching to a synthetic placeholder.
- The selector value should continue to match the controller's `currentPresetName` after fallback rendering.

## How This Differs From Load Failure

An empty collection response is not the same as a failed load.

- Empty collection: the request succeeded and returned no saved preset records for the current owner/scope. The fallback option keeps the selector usable.
- Load/auth/table-key failure: the request did not produce a usable collection. The existing action-specific failure status should be used so the host app can troubleshoot authentication, mount path, owner lookup, or stable `table_key` wiring.

Do not change the JSON API response shape, add a disabled placeholder, or redesign the preset selector just to explain this state. If a host app needs more explicit first-run copy, keep that wording in host-app surrounding UI or a copied editor partial.

## Review Checklist

- `renderPresetOptions()` keeps `preferences: []` from producing an empty selector.
- The fallback option uses `currentPresetName` and remains editable.
- The selector value is reset to `currentPresetName` after rendering options.
- Initial collection load failures continue to use `loadingFailedStatusLabel` rather than the empty-list fallback.
- Read-only scoped preset behavior is not changed by this fallback note.
