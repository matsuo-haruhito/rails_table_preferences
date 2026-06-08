# Preset name save boundary

This note explains the current bundled editor boundary between the saved preset selector and the preset name input.

## Current contract

The preset selector chooses which saved settings to load or switch to.

The preset name input is the name that save and save as new use as the save target.

If a user selects an existing preset, edits the preset name input, and saves, the bundled editor treats the typed name as the save target. It does not present that action as an in-place rename of the previously selected preset.

Host applications can still describe this with their own product wording through locale overrides, but the copy should not imply that changing the text field renames the selected preset unless the host app has added that custom behavior.

## Recommended wording boundary

Use wording that keeps these ideas separate:

- selector: load or switch saved settings
- name input: choose the name used when saving
- save: update the settings for the name currently in the input
- save as new: create a separately named preset from the current editor state

Avoid wording that says the selected preset itself is renamed by editing the input.

## Manual QA

For screens that customize bundled editor copy, check this flow:

1. Select a named preset and confirm it loads.
2. Change the preset name input to a different name.
3. Save the current settings.
4. Confirm the UI copy made it clear that the input name was the save target, not an in-place rename of the previously selected preset.
5. Confirm read-only scoped preset copy still says saves fall back to the owner preset path rather than overwriting the scoped preset.

## Non-goals

This note does not add a rename API, preset management screen, duplicate-name resolver, or custom confirmation flow. Host applications that need those behaviors should own them in copied markup, copied controller code, or a separate management UI.