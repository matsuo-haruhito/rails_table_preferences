# Preset name save boundary

This note explains the current bundled editor boundary between the saved preset selector and the preset name input.

## Current contract

The preset selector chooses which saved settings to load or switch to.

The preset name input is the name that save and save as new use as the save target.

If a user selects an existing preset, edits the preset name input, and saves, the bundled editor treats the typed name as the save target. It does not present that action as an in-place rename of the previously selected preset.

Host applications can still describe this with their own product wording through locale overrides, but the copy should not imply that changing the text field renames the selected preset unless the host app has added that custom behavior.

## First-run empty collection fallback

When the preset collection is empty, the bundled editor keeps the selector populated with the current preset name fallback. This avoids an empty select on first-run screens, but the fallback option does not mean a saved preset already exists.

Keep first-run empty state and load failure wording separate. An empty collection is a valid starting state that still lets users apply, save, or save as new. A load failure is an async error state; the selector may still show the current preset name, but users should check the connection and reload before trusting the saved preset list.

## Recommended wording boundary

Use wording that keeps these ideas separate:

- selector: load or switch saved settings
- name input: choose the name used when saving
- first-run fallback: current preset name shown while no saved presets exist yet
- load failure fallback: current preset name shown because the saved preset list could not be loaded
- save: update the settings for the name currently in the input
- save as new: create a separately named preset from the current editor state

Avoid wording that says the selected preset itself is renamed by editing the input.

## Manual QA

For screens that customize bundled editor copy, check this flow:

1. Start with a preset collection response that has no saved presets and confirm the selector shows only the current preset name.
2. Confirm the copy does not imply that the fallback option is already a saved preset.
3. Select a named preset and confirm it loads.
4. Change the preset name input to a different name.
5. Save the current settings.
6. Confirm the UI copy made it clear that the input name was the save target, not an in-place rename of the previously selected preset.
7. Confirm read-only scoped preset copy still says saves fall back to the owner preset path rather than overwriting the scoped preset.
8. Simulate or inspect the preset list load failure path and confirm the failure copy asks users to reload instead of presenting the current preset name as a saved option.

## Non-goals

This note does not add a rename API, preset management screen, duplicate-name resolver, custom confirmation flow, JSON API response shape, or different preset selector component. Host applications that need those behaviors should own them in copied markup, copied controller code, or a separate management UI.
